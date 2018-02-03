;
;  swiftformat-project-settings.el
;  Swiftformat
;
;  Created by Dave Abrahams on 20/09/17
;  Copyright © 2017 Apple Inc. All rights reserved.
;

;; Associate .swift files with swift-mode
(setq auto-mode-alist
   (append '(("\\.swift$" . swift-mode) ("\\.gyb$" python-mode t)) auto-mode-alist))

;; Try to ensure that swift-mode is in the load-path
(add-to-list 'load-path (expand-file-name (concat (file-name-directory load-file-name) "/../../../s/swift/utils")))
(autoload 'swift-mode "swift-mode"
  "Major mode for editing SWIFT source files.
  \\{swift-mode-map}
  Runs swift-mode-hook on startup."
  :interactive
  )

(require 'cc-styles)

;; When this file is loaded in response to visiting a file in the project, it
;; won't have had its major mode set up according to the project settings yet.
;; For example, Swift files may come up in Fundamental mode unless we do
;; something.  This hack causes the file to be re-mode-ed.
(set-auto-mode)

(defun swiftformat-project-comment-end ()
  "If comment-end is non-empty returns it, stripped of leading whitespace.  Returns nil otherwise"
  (replace-regexp-in-string
   "\\` +" ""
   (if (and comment-end (> (length comment-end) 0)) comment-end v1)))

(define-skeleton swiftformat-header
  "Insert the Swiftformat header at the top of a file

Note: this skeleton presently assumes that comment-start creates
a comment until end-of-line.  Handling paired comment syntax is
possible, but more work, and someone needs to decide what such an
Swiftformat header should look like.
"
  ;; prompt
  nil

  ;; v1 is comment-start without trailing whitespace.  Presumably
  ;; nobody is crazy enough to define a language where whitespace
  ;; determines whether something is a comment, but c++ mode and
  ;; friends have a space at the end of comment-start, which messes up
  ;; the Swiftformat header format.
  ;;
  ;; When there's no comment syntax defined, we use "#"; precedent is
  ;; in the project's README file.
  '(setq v1 (replace-regexp-in-string " +\\'" "" (or comment-start "#")))

  ;; v2 is the name of the file
  '(setq v2 (file-name-nondirectory (buffer-file-name)))

  '(setq v3 user-full-name)

  '(setq v4 (format-time-string "%d/%m/%y"))

  '(setq v5 (format-time-string "%Y"))

  v1 "\n"
  v1 "  " v2 "\n"
  v1 "  Swiftformat\n"
  v1 "\n"
  v1 "  Created by " v3 " on " v4 "\n"
  v1 "  Copyright © " v5 " Apple Inc. All rights reserved.\n"
  v1 "\n"
)

(defvar swiftformat-project-auto-insert-alist
  ;; Currently we match any file and insert the Swiftformat header.  We can
  ;; make the regexp more specific or filter based on mode if this
  ;; doesn't work out.
  '((("" . "Swiftformat header") . swiftformat-header))
  "auto-insert-alist entries that are just for the Swiftformat project"
  )

(defadvice auto-insert (around swiftformat-project-auto-insert activate)
  "Modify auto-insert so that swiftformat-project-auto-insert-alist
takes precedence for files in the Swiftformat project"
  ;; Assume that files with c-file-style set to "swiftformat" are
  ;; part of the Swiftformat project.  Because it's set in
  ;; .dir-locals.el, this will apply to all files, not just
  ;; those using cc-mode
  (if (and (boundp 'c-file-style) (equal c-file-style "swiftformat"))
      (let ((auto-insert-alist
             (append swiftformat-project-auto-insert-alist auto-insert-alist))
            ;; The default is to ask when creating a new file.  Inside
            ;; this project, we always want the Swiftformat header, so only
            ;; prompt if the user has set auto-insert to /always/
            ;; prompt.
            (auto-insert-query (if (eq auto-insert-query 'function) nil auto-insert-query)))
        ad-do-it)
    ad-do-it))

(provide 'swiftformat-project-settings)
;; end of swiftformat-project-settings.el
