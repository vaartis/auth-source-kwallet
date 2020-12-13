;;; kwallet-auth-source.el --- KWallet integration for auth-source

;;; Copyright (C) 2020 Ekaterina Vaartis

;;; Author: Ekaterina Vaartis <vaartis@kotobank.ch>
;;; Created: 13 Dec 2020
;;; URL: https://github.com/vaartis/kwallet-auth-source

;;; Package-Requires: ((emacs "24.4"))

;;; Commentary:
;;; This package adds kwallet support to auth-source by calling
;;; kwallet-query from the command line.

;;; Code:

(require 'auth-source)

(defgroup kwallet-auth-source nil
  "KWallet auth source settings."
  :group 'external
  :tag "kwallet-auth-source"
  :prefix "kwallet-")

(defcustom kwallet-auth-source-wallet "Passwords"
  "KWallet wallet to use."
  :type 'string
  :group 'kwallet-auth-source)

(defcustom kwallet-auth-source-folder "Passwords"
  "KWallet folder to use."
  :type 'string
  :group 'kwallet-auth-source)

(defcustom kwallet-auth-source-key-separator "@"
  "Separator to use between the user and the host for KWallet."
  :type 'string
  :group 'kwallet-auth-source)

(cl-defun kwallet-auth-source--kwallet-search (&rest spec
                                                     &key backend type host user port
                                                     &allow-other-keys)
  "Searche KWallet for the specified user and host.
SPEC, BACKEND, TYPE, HOST, USER and PORT are as required by auth-source."
  (let ((got-secret (string-trim
                     (shell-command-to-string
                      (concat "kwallet-query " kwallet-auth-source-wallet
                              " -f " kwallet-auth-source-folder
                              " -r " (concat user kwallet-auth-source-key-separator host))))))
    (list (list :user user
                :secret got-secret))))

(defun kwallet-auth-source--kwallet-backend-parse (entry)
  "Parse the entry to check if this is a kwallet entry.
ENTRY is as required by auth-source."
  (when (eq entry 'kwallet)
    (auth-source-backend-parse-parameters
     entry
     (auth-source-backend
      :source "."
      :type 'kwallet
      :search-function #'kwallet-auth-source--kwallet-search))))

;;;###autoload
(defun kwallet-auth-source-enable ()
  "Enable the kwallet auth source."
  (add-to-list 'auth-sources 'kwallet)
  (auth-source-forget-all-cached))

(advice-add 'auth-source-backend-parse
            :before-until
            #'kwallet-auth-source--kwallet-backend-parse)

(provide 'kwallet-auth-source)
;;; kwallet-auth-source.el ends here
