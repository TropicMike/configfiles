(when (eq system-type 'windows-nt)
  (setq default-directory (expand-file-name "~/Desktop/")))
(load-theme 'wombat)
(add-to-list 'auto-mode-alist '("/\\.aliases\\'" . sh-mode))
(global-font-lock-mode 1) ; turn on syntax coloring
(show-paren-mode 1) ; turn on paren match highlighting
(setq show-paren-style 'expression) ; highlight entire bracket expression
(column-number-mode 1)
(add-to-list 'default-frame-alist '(width . 120)) ; character
(add-to-list 'default-frame-alist '(height . 40)) ; lines
(setq mouse-yank-at-point t)
(put 'upcase-region 'disabled nil)
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)
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
 '(default ((t (:slant normal :weight normal :height 140 :width normal)))))
(cond
 ((find-font (font-spec :name "Consolas")) (set-frame-font "Consolas-14" nil t))
 ((find-font (font-spec :name "Menlo")) (set-frame-font "Menlo-14" nil t))
 ((find-font (font-spec :name "DejaVu Sans Mono")) (set-frame-font "DejaVu Sans Mono-14" nil t))
 ((find-font (font-spec :name "Courier New")) (set-frame-font "Courier New-14" nil t)))
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
