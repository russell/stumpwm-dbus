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
  (:import-from #:cl-cont
                #:with-call/cc
                #:call/cc
                #:let/cc)
  (:import-from #:dbus
                #:system-server-addresses
                #:with-open-bus
                #:connection
                #:bus-connection
                #:method-return-message
                #:with-introspected-object
                #:connection-pending-messages
                #:connection-event-base
                #:signal-message
                #:message-reply-serial
                #:connection-next-serial
                #:send-message
                #:encode-message
                #:message-no-reply-expected
                #:hello
                #:message-no-auto-start
                #:object
                #:object-interface
                #:interface-name
                #:parse-introspection-document
                #:message-serial
                #:message-body
                #:error-message
                #:method-error
                #:supported-authentication-mechanisms
                #:bus
                #:authenticate)
  (:import-from #:mailbox
                #:make-mailbox
                #:mailboxp
                #:post-mail
                #:read-mail)
  (:import-from #:cl-async-future
                #:future
                #:make-future
                #:do-add-callback
                #:attach-errback
                #:wait-for
   ))
