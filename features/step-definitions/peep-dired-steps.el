;; This file contains your project specific step definitions. All
;; files in this directory whose names end with "-steps.el" will be
;; loaded automatically by Ecukes.

(Given "^I open dired buffer in the roor directory$"
  (lambda ()
    (dired peep-dired-root-path)
    ))

(And "^I place cursor on \"\\(.+\\)\" file$"
     (lambda (filename)
       (beginning-of-buffer)
       (while (not (string= (dired-get-file-for-visit)
			    (expand-file-name filename))))
       (dired-find-file)))

(When "^I have \"\\(.+\\)\"$"
  (lambda (something)
    ;; ...
    ))

(Then "^I should have \"\\(.+\\)\"$"
  (lambda (something)
    ;; ...
    ))

(And "^I have \"\\(.+\\)\"$"
  (lambda (something)
    ;; ...
    ))

(But "^I should not have \"\\(.+\\)\"$"
  (lambda (something)
    ;; ...
    ))
