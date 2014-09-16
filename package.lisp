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

;;;; package.lisp

(defpackage #:stumpwm.contrib.dbus
  (:use #:cl)
  (:import-from #:stumpwm
                #:add-hook
                #:remove-hook
                #:*internal-loop-hook*)
  (:import-from #:alexandria
                #:with-gensyms
                #:ensure-list)
  (:import-from #:bordeaux-threads
                #:make-thread
                #:thread-alive-p
                #:interrupt-thread
                #:destroy-thread
                #:*default-special-bindings*)
  (:import-from #:iolib.multiplex
                #:event-base
                #:close
                #:add-timer)
  (:import-from #:dbus
                #:authenticate
                #:bus
                #:bus-connection
                #:connection
                #:connection-event-base
                #:connection-next-serial
                #:connection-pending-messages
                #:encode-message
                #:error-message
                #:hello
                #:interface-name
                #:interface-method
                #:message-body
                #:message-no-auto-start
                #:message-no-reply-expected
                #:message-reply-serial
                #:message-serial
                #:message-signature
                #:method-error
                #:method-return-message
                #:method-signature
                #:object
                #:object-interface
                #:object-connection
                #:object-path
                #:object-destination
                #:list-object-interfaces
                #:parse-introspection-document
                #:send-message
                #:signal-message
                #:supported-authentication-mechanisms
                #:system-server-addresses
                #:with-introspected-object
                #:with-open-bus
                )
  (:import-from #:mailbox
                #:make-mailbox
                #:mailboxp
                #:post-mail
                #:read-mail)
  (:import-from #:cl-async-future
                #:future
                #:futurep
                #:make-future
                #:attach-errback
                #:future-values
                #:future-finished-p
                #:attach
                #:finish
                #:alet)

  (:export
   #:make-object-from-introspection
   #:object-invoke
   #:interface-name
   #:list-object-interfaces
   #:with-introspected-object
   #:make-future
   #:futurep
   #:attach
   #:finish
   #:alet
   #:future-finished-p
   #:future-values
   #:with-futures))
