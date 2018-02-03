;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((nil
  (eval let*
        ((x (dir-locals-find-file default-directory))
         (this-directory (if (listp x) (car x) (file-name-directory x))))
        (unless (or (featurep 'swiftformat-project-settings) 
                    (and (fboundp 'tramp-tramp-file-p)
                         (tramp-tramp-file-p this-directory)))
          (add-to-list 'load-path
                       (concat this-directory "Aux")
                       :append)
          (let ((swiftformat-project-directory this-directory))
            (require 'swiftformat-project-settings)))
        (set (make-local-variable 'swiftformat-project-directory)
         this-directory)
        (make-local-variable 'before-save-hook)
        (add-hook 'before-save-hook 'delete-trailing-whitespace)
        )
  (tab-width . 4)
  (fill-column . 80))
 (c++-mode
  (whitespace-style face lines indentation:space))
 (c-mode
  (whitespace-style face lines indentation:space))
 (objc-mode
  (whitespace-style face lines indentation:space))
 (prog-mode
  (eval add-hook 'prog-mode-hook
        (lambda nil
          (whitespace-mode 1))
        (not :APPEND)
        :BUFFER-LOCAL))
 (swift-mode
  (whitespace-style face lines indentation:space)
  (swift-basic-offset . 4)
  (tab-always-indent . t)))



;; Local Variables:
;; eval: (whitespace-mode -1)
;; End:
