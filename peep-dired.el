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

(defvar peep-dired-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<down>")      'peep-dired-next-file)
    (define-key map (kbd "C-n")         'peep-dired-next-file)
    (define-key map (kbd "<up>")        'peep-dired-prev-file)
    (define-key map (kbd "C-p")         'peep-dired-prev-file)
    (define-key map (kbd "<SPC>")       'peep-dired-scroll-page-down)
    (define-key map (kbd "C-<SPC>")     'peep-dired-scroll-page-up)
    (define-key map (kbd "<backspace>") 'peep-dired-scroll-page-up)
    map)
  "Keymap for `peep-dired-mode'.")

(defun peep-dired-next-file ()
  (interactive)
  (when (dired-next-line 1)
    (kill-buffer-if-not-modified peep-dired--marked-to-kill)
    (peep-dired-display-file-other-window)))

(defun peep-dired-prev-file ()
  (interactive)
  (when (dired-previous-line 1)
    (kill-buffer-if-not-modified peep-dired--marked-to-kill)
    (peep-dired-display-file-other-window)))

(defun peep-dired--find-already-visited-file (name)
  (or
   (find-buffer-visiting name)
   (car (or (dired-buffers-for-dir name) ())))
  )

(defun peep-dired--find-file (name)
  (let ((buffer (find-file-noselect name)))
    (setq-local peep-dired--marked-to-kill buffer)
    buffer
    ))

(defun peep-dired-display-file-other-window ()
  (let ((entry-name (dired-file-name-at-point)))
    (window-buffer
     (display-buffer
      (or (peep-dired--find-already-visited-file entry-name)
	  (peep-dired--find-file entry-name))
      t)))
  )

(defun peep-dired-scroll-page-down ()
  (interactive)
  (scroll-other-window))

(defun peep-dired-scroll-page-up ()
  (interactive)
  (scroll-other-window '-))

(defun peep-dired-disable ()
  (let ((current-point (point)))
    (when peep-dired--marked-to-kill
      (kill-buffer-if-not-modified peep-dired--marked-to-kill))
    (jump-to-register :peep_dired_before)
    (goto-char current-point)))

(defun peep-dired-enable ()
  (unless (string= major-mode "dired-mode")
    (error "Run it from dired buffer"))

  (window-configuration-to-register :peep_dired_before)
  (delete-other-windows)
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
