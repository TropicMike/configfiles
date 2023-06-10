(setq default-directory "C:/Users/mikesa/Desktop/" )
(load-theme 'wombat)
(global-font-lock-mode 1) ; turn on syntax coloring
(show-paren-mode 1) ; turn on paren match highlighting
(setq show-paren-style 'expression) ; highlight entire bracket expression
(global-linum-mode 1) ; display line numbers in margin. Emacs 23 only.
(column-number-mode 1)
(tool-bar-mode -1)
(add-to-list 'default-frame-alist '(width . 120)) ; character
(add-to-list 'default-frame-alist '(height . 40)) ; lines
(setq mouse-yank-at-point t)
(put 'upcase-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(inhibit-startup-screen t)
 '(show-paren-mode t)
 '(tool-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Consolas" :foundry "outline" :slant normal :weight normal :height 98 :width normal)))))
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
(put 'downcase-region 'disabled nil)
