;;; uncrustify-mode.el --- Minor mode to automatically uncrustify.

;; Copyright (C) 2012  tabi
;; Author: Tabito Ohtani <koko1000ban@gmail.com>
;; Version: 0.02
;; Keywords: uncrustify

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Installation:

;; drop requirements and this file into a directory in your `load-path',
;; and put these lines into your .emacs file.

;; (require 'uncrusfify-mode)
;; (add-hook 'c-mode-common-hook
;;    '(lambda ()
;;        (uncrustify-mode 1)))

;;; ChangeLog:
;; * 0.01:
;;   Initial version.
;; * 0.02:
;;   Added uncrustify-fragment().

;;; Variables:

(defcustom uncrustify-config-path
  "~/.uncrustify.cfg"
  "uncrustify config file path"
  :group 'uncrustify
  :type 'file)
(make-variable-buffer-local 'uncrustify-config-path)

(defcustom uncrustify-bin
  "uncrustify -q"
  "The command to run uncrustify."
  :group 'uncrustify
  :type 'string)

;;; Functions:

(defun uncrustify-get-lang-from-mode (&optional mode)
  "uncrustify lang option"
  (let ((m (or mode major-mode)))
    (cl-case m
      (c-mode "C")
      (c++-mode "CPP")
      (d-mode "D")
      (csharp-mode "CS")
      (java-mode "JAVA")
      (objc-mode "OC")
      (t
       nil))))

(defun uncrustify-invoke-command (lang start-in end-in &optional fragment)
  "Run uncrustify on the current region or buffer."
  (if lang
      (let ((start (or start-in (point-min)))
            (end   (or end-in   (point-max)))
            (cmd (concat uncrustify-bin " -c " uncrustify-config-path " -l " lang (if fragment " --frag ")))
            (error-buf (get-buffer-create "*uncrustify-errors*")))

        (with-current-buffer error-buf (erase-buffer))

        (let ((result
               (save-excursion
                 (let ((ret (shell-command-on-region start end cmd t t error-buf nil)))
                   (if (and
                        (numberp ret)
                        (zerop ret))
                       ;; Success! Clean up.
                       (progn
                         (message "Success! uncrustify modified buffer.")
                         (kill-buffer error-buf)
                         t)
                     ;; Oops! Show our error and give back the text that
                     ;; shell-command-on-region stole.
                     (progn (undo)
                            (with-current-buffer error-buf
                              (message "uncrustify error: <%s> <%s>" ret (buffer-string)))
                            nil))))))

          (not result)))
    (message "uncrustify does not support this mode : %s" major-mode)))

(defun uncrustify ()
  (interactive)
  (save-restriction
    (widen)
    (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (region-beginning) (region-end))))

(defun uncrustify-fragment ()
  (interactive)
  (save-restriction
    (widen)
    (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (region-beginning) (region-end) t)))

(defun uncrustify-buffer ()
  (interactive)
  (save-restriction
    (widen)
    (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (point-min) (point-max))))

;;; mode

(defun uncrustify-write-hook ()
  "Uncrustifys a buffer during `write-file-hooks' for `uncrustify-mode'.
   if uncrustify returns not nil then the buffer isn't saved."
  (if (bound-and-true-p uncrustify-mode)
      (save-restriction
        (widen)
        (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (point-min) (point-max)))))

;;;###autoload
(define-minor-mode uncrustify-mode
  "Automatically `uncrustify' when saving."
  :lighter " Uncrustify"
  (if (not (uncrustify-get-lang-from-mode))
      (message "uncrustify does not support this mode : %s" major-mode)
    (if uncrustify-mode
        (add-hook 'write-file-functions 'uncrustify-write-hook nil t)
      (remove-hook 'write-file-functions 'uncrustify-write-hook t))))

(provide 'uncrustify-mode)

;;; uncrustify-mode.el ends here
