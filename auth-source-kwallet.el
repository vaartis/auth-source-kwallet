;;; auth-source-kwallet.el --- KWallet integration for auth-source -*- lexical-binding: t; -*-

;;; Copyright (C) 2020 Ekaterina Vaartis
;;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Author: Ekaterina Vaartis <vaartis@kotobank.ch>
;;; Created: 13 Dec 2020
;;; URL: https://github.com/vaartis/auth-source-kwallet

;;; Package-Requires: ((emacs "24.4"))

;;; Version: 0.0.2

;;; Commentary:
;; This package adds kwallet support to auth-source by calling
;; kwallet-query from the command line.

;;; Code:

(require 'auth-source)

(defgroup auth-source-kwallet nil
  "KWallet auth source settings."
  :group 'external
  :tag "auth-source-kwallet"
  :prefix "kwallet-")

(defcustom auth-source-kwallet-wallet "Passwords"
  "KWallet wallet to use."
  :type 'string
  :group 'auth-source-kwallet)

(defcustom auth-source-kwallet-folder "Passwords"
  "KWallet folder to use."
  :type 'string
  :group 'auth-source-kwallet)

(defcustom auth-source-kwallet-key-separator "@"
  "Separator to use between the user and the host for KWallet."
  :type 'string
  :group 'auth-source-kwallet)

(defcustom auth-source-kwallet-executable "kwallet-query"
  "Executable used to query kwallet."
  :type 'string
  :group 'auth-source-kwallet)

(cl-defun auth-source-kwallet--kwallet-search (&rest spec
                                                     &key _backend _type host user _port
                                                     &allow-other-keys)
  "Searche KWallet for the specified user and host.
SPEC, BACKEND, TYPE, HOST, USER and PORT are as required by auth-source."
  (if (executable-find auth-source-kwallet-executable)
      (let ((output-buffer (generate-new-buffer "*kwallet-output*")))
        (unwind-protect
            (let ((exit-status (call-process auth-source-kwallet-executable
                                             nil output-buffer nil
                                             auth-source-kwallet-wallet
                                             "-f" auth-source-kwallet-folder
                                             "-r" (concat user auth-source-kwallet-key-separator host))))
              (if (zerop exit-status)
                  (with-current-buffer output-buffer
                    (list (list :user user
                                :secret (string-trim (buffer-string)))))
                ;; Any non-zero exit status indicates a failure, so return nil.
                nil))
          (kill-buffer output-buffer)))
    ;; If not executable was found, return nil and show a warning
    (warn (format "`auth-source-kwallet': Could not find executable '%s' to query KWallet", auth-source-kwallet-executable))))

(defun auth-source-kwallet--kwallet-backend-parse (entry)
  "Parse the entry to check if this is a kwallet entry.
ENTRY is as required by auth-source."
  (when (eq entry 'kwallet)
    (auth-source-backend-parse-parameters
     entry
     (auth-source-backend
      :source "KWallet"
      :type 'kwallet
      :search-function #'auth-source-kwallet--kwallet-search))))

;;;###autoload
(defun auth-source-kwallet-enable ()
  "Enable the kwallet auth source."

  (advice-add 'auth-source-backend-parse
              :before-until
              #'auth-source-kwallet--kwallet-backend-parse)
  (add-to-list 'auth-sources 'kwallet)
  (auth-source-forget-all-cached))

(provide 'auth-source-kwallet)

;;; auth-source-kwallet.el ends here
