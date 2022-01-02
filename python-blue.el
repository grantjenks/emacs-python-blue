;;; python-blue.el --- Reformat Python buffers using the "blue" formatter -*- lexical-binding: t -*-
;;
;; Copyright (c) 2022 Grant Jenks
;;
;; Author: Grant Jenks <grant.jenks@gmail.com>
;; Homepage: https://github.com/grantjenks/emacs-python-blue
;; Package-Requires: ((emacs "27.2"))
;; Version: 0.0.1
;; SPDX-License-Identifier: MIT
;;
;; MIT License
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to
;; deal in the Software without restriction, including without limitation the
;; rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
;; sell copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
;; IN THE SOFTWARE.
;;
;;; Commentary:
;;
;; Python-blue uses blue to format a Python buffer. It can be called explicitly
;; on a certain buffer, but more conveniently, a minor-mode 'python-blue-mode'
;; is provided that turns on automatically running blue on a buffer before
;; saving.
;;
;; Installation:
;;
;; Add python-blue.el to your load-path.
;;
;; To automatically format all Python buffers before saving, add the
;; function python-blue-mode to python-mode-hook:
;;
;; (add-hook 'python-mode-hook #'python-blue-mode)
;;
;;; Code:

(defgroup python-blue nil
  "Reformat Python code with \"blue\"."
  :group 'python)

(defcustom python-blue-executable "blue"
  "Name of the executable to run."
  :type 'string)

(defcustom python-blue-only-if-project-is-blued t
  "Only run blue if project has blue configured."
  :type 'boolean
  :safe 'booleanp)

(defun python-blue-call-bin (input-buffer output-buffer error-buffer)
  "Call process blue.

Send INPUT-BUFFER content to the process stdin. Saving the output
to OUTPUT-BUFFER. Saving process stderr to ERROR-BUFFER. Return
blue process the exit code."
  (with-current-buffer input-buffer
    (let ((process (make-process :name "python-blue"
                                 :command `(,python-blue-executable ,@(python-blue-call-args))
                                 :buffer output-buffer
                                 :stderr error-buffer
                                 :noquery t)))
      (set-process-query-on-exit-flag (get-buffer-process error-buffer) nil)
      (save-restriction
        (widen)
        (process-send-region process (point-min) (point-max)))
      (process-send-eof process)
      (accept-process-output process nil nil t)
      (while (process-live-p process)
        (accept-process-output process nil nil t))
      (process-exit-status process))))

(defun python-blue-call-args ()
  "Build blue process call arguments."
  (append
   (when (and (buffer-file-name (current-buffer))
              (string-match "\\.pyi" (buffer-file-name (current-buffer))))
     (list "--pyi"))
   '("-")))

(defun python-blue-project-is-python-blued ()
  "Whether the project is configured to use blue."
  (or
   (when-let ((parent (locate-dominating-file default-directory "pyproject.toml")))
     (with-temp-buffer
       (insert-file-contents (concat parent "pyproject.toml"))
       (re-search-forward "^\\[tool.blue\\]$" nil t 1)))
   (when-let ((parent (locate-dominating-file default-directory "tox.ini")))
     (with-temp-buffer
       (insert-file-contents (concat parent "tox.ini"))
       (re-search-forward "^\\[blue\\]$" nil t 1)))
   (when-let ((parent (locate-dominating-file default-directory "setup.cfg")))
     (with-temp-buffer
       (insert-file-contents (concat parent "setup.cfg"))
       (re-search-forward "^\\[blue\\]$" nil t 1)))
   (when-let ((parent (locate-dominating-file default-directory ".blue")))
     (with-temp-buffer
       (insert-file-contents (concat parent ".blue"))
       (re-search-forward "^\\[blue\\]$" nil t 1)))))

;;;###autoload
(defun python-blue-buffer (&optional display)
  "Try to python-blue the current buffer.

Show blue output, if blue exits abnormally and DISPLAY is t."
  (interactive (list t))
  (let* ((original-buffer (current-buffer))
         (original-point (point))
         (original-window-pos (window-start))
         (tmpbuf (get-buffer-create "*python-blue*"))
         (errbuf (get-buffer-create "*python-blue-error*")))
    ;; This buffer can be left after previous black invocation.  It
    ;; can contain error message of the previous run.
    (dolist (buf (list tmpbuf errbuf))
      (with-current-buffer buf
        (erase-buffer)))
    (condition-case err
        (if (not (zerop (python-blue-call-bin original-buffer tmpbuf errbuf)))
            (error "Blue failed, see %s buffer for details" (buffer-name errbuf))
          (unless (eq (compare-buffer-substrings tmpbuf nil nil original-buffer nil nil) 0)
            (with-current-buffer tmpbuf
              (copy-to-buffer original-buffer (point-min) (point-max)))
            (goto-char original-point)
            (set-window-start (selected-window) original-window-pos))
          (mapc #'kill-buffer (list tmpbuf errbuf)))
      (error (message "%s" (error-message-string err))
             (when display
               (with-current-buffer errbuf
                 (setq-local scroll-conservatively 0))
               (pop-to-buffer errbuf))))))

;;;###autoload
(define-minor-mode python-blue-mode
  "Automatically run blue before saving."
  :lighter " Blue"
  (if python-blue-mode
      (when (or (not python-blue-only-if-project-is-blued)
                (python-blue-project-is-python-blued))
        (add-hook 'before-save-hook #'python-blue-buffer nil t))
    (remove-hook 'before-save-hook #'python-blue-buffer t)))

(provide 'python-blue)

;;; python-blue.el ends here
