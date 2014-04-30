(require 'f)

(defvar peep-dired-support-path
  (f-dirname load-file-name))

(defvar peep-dired-features-path
  (f-parent peep-dired-support-path))

(defvar peep-dired-root-path
  (f-parent peep-dired-features-path))

(add-to-list 'load-path peep-dired-root-path)

(require 'peep-dired)
(require 'espuds)
(require 'ert)

(Setup
 ;; Before anything has run
 )

(Before
 ;; Before each scenario is run
 )

(After
 ;; After each scenario is run
 )

(Teardown
 ;; After when everything has been run
 )
