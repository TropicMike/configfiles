(global-font-lock-mode t)
(put 'upcase-region 'disabled nil)
(global-font-lock-mode 1) ; turn on syntax coloring
(show-paren-mode 1) ; turn on paren match highlighting
(setq show-paren-style 'expression) ; highlight entire bracket expression
(column-number-mode 1)
(transient-mark-mode 1)
(setq mouse-yank-at-point t)
(custom-set-variables
;; custom-set-variables was added by Custom.
;; If you edit it by hand, you could mess it up, so be careful.
;; Your init file should contain only one such instance.
;; If there is more than one, they won't work right.
'(inhibit-startup-screen t))
(custom-set-faces
;; custom-set-faces was added by Custom.
;; If you edit it by hand, you could mess it up, so be careful.
;; Your init file should contain only one such instance.
;; If there is more than one, they won't work right.
)
(defun uniq-lines (beg end)
  "Unique lines in region.
Called from a program, there are two arguments:
BEG and END (region to sort)."
  (interactive "r")
  (save-excursion
  (save-restriction
  (narrow-to-region beg end)
  (goto-char (point-min))
  (while (not (eobp))
  (kill-line 1)
  (yank)
  (let ((next-line (point)))
  (while
  (re-search-forward
  (format "^%s" (regexp-quote (car kill-ring))) nil t)
  (replace-match "" nil nil))
  (goto-char next-line))))))
