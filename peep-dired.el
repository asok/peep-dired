;;; peep-dired.el --- Peep at files in another window from dired buffers

;; Copyright (C) 2014  Adam Sokolnicki

;; Author: Adam Sokolnicki <adam.sokolnicki@gmail.com>
;; Keywords: files, convenience

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

;;; Commentary:

;; This is a minor mode that can be enabled from a dired buffer.
;; Once enabled it will show the file from point in the other window.
;; Moving to the other file within the dired buffer with <down>/<up> or
;; C-n/C-p will display different file.
;; Hitting <SPC> will scroll the peeped file down, whereas
;; C-<SPC> and <backspace> will scroll it up.

;;; Code:

(require 'cl-macs)

(defvar peep-dired-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<down>")      'peep-dired-next-file)
    (define-key map (kbd "C-n")         'peep-dired-next-file)
    (define-key map (kbd "<up>")        'peep-dired-prev-file)
    (define-key map (kbd "C-p")         'peep-dired-prev-file)
    (define-key map (kbd "<SPC>")       'peep-dired-scroll-page-down)
    (define-key map (kbd "C-<SPC>")     'peep-dired-scroll-page-up)
    (define-key map (kbd "<backspace>") 'peep-dired-scroll-page-up)
    (define-key map (kbd "q")           'peep-dired)
    map)
  "Keymap for `peep-dired-mode'.")

(defvar peep-dired-display-file-hook nil
  "Hook run when displaying a file using peep-dired.")

(defvar peep-dired-peeped-buffers ()
  "List with buffers of peeped files")

(defcustom peep-dired-cleanup-on-disable t
  "Cleanup opened buffers when disabling the minor mode"
  :group 'peep-dired
  :type 'boolean)

(defcustom peep-dired-cleanup-eagerly nil
  "Cleanup opened buffers upon `peep-dired-next-file' & `peep-dired-prev-file'"
  :group 'peep-dired
  :type 'boolean)

(defcustom peep-dired-enable-on-directories t
  "When t it will enable the mode when visiting directories"
  :group 'peep-dired
  :type 'boolean)

(defcustom peep-dired-ignored-extensions
  '("mkv" "iso" "mp4")
  "Extensions to not try to open"
  :group 'peep-dired
  :type 'list)

(defcustom peep-dired-max-size (* 100 1024 1024)
  "Do to not try to open file exteeds this size"
  :group 'peep-dired
  :type 'integer)

(defcustom peep-dired-display-action-alist nil
  "Action alist for display-buffer action function used to
  peep."
  :group 'peep-dired
  :type 'list)

(defcustom peep-dired-preview-excluded-hooks
  '(epa-file-find-file-hook
    recentf-track-opened-file
    vc-refresh-state)
  "List of `find-file' hooks, which should not be executed during file preview.
In particular we don't want to modify the list of recent files and we
don't want to see epa password prompts."
  :group 'peep-dired
  :type '(repeat symbol))

(defvar peep-dired--active-window nil
  "Currently peeeped (opened) window")

(defun peep-dired-next-file (&optional arg)
  (interactive "p")
  (if (window-live-p peep-dired--active-window)
      (delete-window peep-dired--active-window))
  (dired-next-line (or arg 1))
  (peep-dired-display-file-other-window)
  (when peep-dired-cleanup-eagerly
    (peep-dired-cleanup)))

(defun peep-dired-prev-file (&optional arg)
  (interactive "p")
  (if (window-live-p peep-dired--active-window)
      (delete-window peep-dired--active-window))
  (dired-previous-line (or arg 1))
  (peep-dired-display-file-other-window)
  (when peep-dired-cleanup-eagerly
    (peep-dired-cleanup)))

(defun peep-dired-kill-buffers-without-window ()
  "Will kill all peep buffers that are not displayed in any window"
  (interactive)
  (cl-loop for buffer in peep-dired-peeped-buffers do
           (unless (get-buffer-window buffer t)
             (kill-buffer-if-not-modified buffer))))

(defun peep-dired-dir-buffer (entry-name)
  (with-current-buffer (or
                        (car (or (dired-buffers-for-dir entry-name) ()))
                        (dired-noselect entry-name))
    (when peep-dired-enable-on-directories
      (setq peep-dired 1)
      (run-hooks 'peep-dired-hook))
    (current-buffer)))

(defun peep-dired-display-file-other-window ()
  (let ((entry-name (dired-file-name-at-point)))
    (unless (or (member (file-name-extension entry-name)
                        peep-dired-ignored-extensions)
                (> (nth 7 (file-attributes entry-name))
                   peep-dired-max-size))
      (setq peep-dired--active-window
            (display-buffer
             (if (file-directory-p entry-name)
                 (peep-dired-dir-buffer entry-name)
               (or
                (find-buffer-visiting entry-name)
                (cl-letf (((default-value 'find-file-hook)
                           (seq-remove
                            (lambda (x)
                              (memq x peep-dired-preview-excluded-hooks))
                            (default-value 'find-file-hook))))
                  (find-file-noselect entry-name))))
             (or peep-dired-display-action-alist t)))
      (with-current-buffer (window-buffer peep-dired--active-window)
        (run-hooks 'peep-dired-display-file-hook))
      (add-to-list 'peep-dired-peeped-buffers
                   (window-buffer peep-dired--active-window)))))

(defun peep-dired-scroll-page-down ()
  (interactive)
  (scroll-other-window))

(defun peep-dired-scroll-page-up ()
  (interactive)
  (scroll-other-window '-))

(defun peep-dired-cleanup ()
  (mapc 'kill-buffer-if-not-modified peep-dired-peeped-buffers)
  (setq peep-dired-peeped-buffers ()))

(defun peep-dired-disable ()
  (let ((current-point (point)))
    ;; (jump-to-register :peep_dired_before)
    (if (window-live-p peep-dired--active-window)
        (delete-window peep-dired--active-window))
    (when peep-dired-cleanup-on-disable
      (mapc 'kill-buffer-if-not-modified peep-dired-peeped-buffers))
    (setq peep-dired-peeped-buffers ())
    (goto-char current-point)))

(defun peep-dired-enable ()
  (unless (string= major-mode "dired-mode")
    (error "Run it from dired buffer"))

  ;; (window-configuration-to-register :peep_dired_before)
  ;; (delete-other-windows)
  (peep-dired-display-file-other-window))

;;;###autoload
(define-minor-mode peep-dired
  "A convienent way to look up file contents in other window while browsing directory in dired"
  :init-value nil
  :lighter " Peep"
  :keymap peep-dired-mode-map

  (if peep-dired
      (peep-dired-enable)
    (peep-dired-disable)))

(provide 'peep-dired)

;;; peep-dired.el ends here
