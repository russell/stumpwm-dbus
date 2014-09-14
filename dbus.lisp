;;; DBUS integration for StumpWM
;;;
;;; Copyright 2014 Russell Sim <russell.sim@gmail.com>
;;;
;;; This module is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3, or (at your option)
;;; any later version.
;;;
;;; This module is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this software; see the file COPYING.  If not, see
;;; <http://www.gnu.org/licenses/>.

;;;; stumpwm-dbus.lisp

(in-package #:stumpwm.contrib.dbus)

(defvar *event-base* nil)
(defvar *connection* nil)
(defvar *dbus* nil)
(defvar *in-queue* (make-mailbox)
  "The list of responses being returned to StumpWM.")
(defvar *out-queue* (make-mailbox)
  "The list of messages being sent to DBUS.")
(defvar *message-dispatch* (make-hash-table))
(defvar *internal-dispatch* (make-hash-table))
(defvar *responses* (make-hash-table))
(defvar *thread* nil)


(defun dbus-event-loop ()
  (iolib.multiplex:event-dispatch (connection-event-base *connection*)))

(defun open-connection ()
  (setf *event-base* (make-instance 'event-base))
  (setf *connection*
        (dbus:open-connection *event-base* (system-server-addresses) :if-failed :error))
  (authenticate (supported-authentication-mechanisms *connection*) *connection*)
  (let ((serial (dbus:invoke-method *connection* "Hello"
                                    :path "/org/freedesktop/DBus"
                                    :interface "org.freedesktop.DBus"
                                    :destination "org.freedesktop.DBus" :asynchronous t)))
    (flet ((set-dbus (message)
             (setf *dbus* (make-instance 'bus :name message
                                              :connection *connection*))))
      (setf (gethash serial *message-dispatch*) #'set-dbus)))
  (let ((*default-special-bindings*
          (acons '*connection* *connection*
                 *default-special-bindings*)))
    (setf *thread* (make-thread 'dbus-event-loop
                                :name "dbus")))
  ;; Hook into StumpWM loop
  (add-hook  *internal-loop-hook* 'handle-pending-messages)
  *connection*)

(defun close-connection ()
  ;; Remove hook from StumpWM loop
  (remove-hook  *internal-loop-hook* 'handle-pending-messages)
  (when (and *thread* (thread-alive-p *thread*))
    (destroy-thread *thread*))
  (when *connection* (dbus:close-connection *connection*))
  (when *event-base* (close *event-base*))

  (setf *dbus* nil
        *event-base* nil
        *connection* nil
        *thread* nil))


(defmethod (setf connection-pending-messages) :around (message (connection connection))
  "Queue messages in a thread safe queue instead of on the connection
class."
  (let ((message (car message)))
    (etypecase message
      (method-return-message
       (let ((fn (gethash (message-reply-serial message) *internal-dispatch*)))
         (if fn
             (funcall fn message)
             (post-mail message *in-queue*))))
      (signal-message nil)
      (error-message
       (let ((fn (gethash (message-reply-serial message) *internal-dispatch*)))
         (if fn
             (funcall fn message)
             (post-mail message *in-queue*)))))))

(defvar *last-message* nil)
(defun handle-pending-messages ()
  (loop :for message = (read-mail *in-queue*)
        :when message
          :do (format t "Received ~a~%" message)
        :while message
        :do (etypecase message
              (method-return-message (let ((fn (gethash (message-reply-serial message) *message-dispatch*)))
                                       (if fn
                                        (funcall fn message)
                                        (setf *last-message* message))))
              (signal-message nil)
              (error-message (error 'method-error :arguments (message-body message))))))

(defun process-outgoing-messages ()
  (loop :for message = (read-mail *out-queue*)
        :when message
          :do (format t "Sending ~a~%" message)
        :while message
        :do (send-message message *connection*)))

(defun make-object (connection path destination interfaces)
  (let ((object (make-instance 'object :connection connection :path path :destination destination)))
    (dolist (interface interfaces)
      (setf (object-interface (interface-name interface) object) interface))
    object))

(defun invoke-method1 (member
                       &key (connection *connection*) path signature arguments interface
                         destination no-reply no-auto-start (endianness :little-endian))
  (let ((serial (connection-next-serial connection)))
   (list
    serial
    (encode-message endianness :method-call
                    (logior (if no-reply message-no-reply-expected 0)
                            (if no-auto-start message-no-auto-start 0))
                    1 serial path
                    interface member nil nil
                    destination nil signature arguments))))


(defun invoke-method (member call-back
                      &key (connection *connection*) path signature arguments interface
                        destination no-reply no-auto-start (dispatch *message-dispatch*))
  (destructuring-bind (serial message)
      (invoke-method1 member
                      :connection connection
                      :path path
                      :signature signature
                      :arguments arguments
                      :interface interface
                      :destination destination
                      :no-reply no-reply
                      :no-auto-start no-auto-start)
    (setf (gethash serial dispatch) call-back)
    (post-mail message *out-queue*)
    (interrupt-thread *thread* 'process-outgoing-messages)))

(defun fetch-introspection-document (call-back path destination &key (connection *connection*))
  (invoke-method "Introspect"
                 call-back
                 :path path
                 :connection connection
                 :destination destination
                 :interface "org.freedesktop.DBus.Introspectable"))

(defun make-object-from-introspection (path destination &key (connection *connection*))
  (let ((response-symbol (gensym)))
    (with-call/cc
      (setf (gethash response-symbol *responses*)
            (make-object connection path destination
                         (parse-introspection-document
                          (car
                           (message-body
                            (let/cc k
                              (fetch-introspection-document k path destination))))))))
    response-symbol))


(defun nm-current-state ()
  (let ((response-symbol (make-object-from-introspection "/org/freedesktop/NetworkManager"
                                                         "org.freedesktop.NetworkManager")))
    (loop
      :do (handle-pending-messages)
      :until (gethash response-symbol *responses*))
    (gethash response-symbol *responses*)))
