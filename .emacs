;; On Windows, open new buffers relative to the Desktop instead of the
;; (often awkward) directory Emacs is launched from.
(when (eq system-type 'windows-nt)
  (setq default-directory (expand-file-name "~/Desktop/")))

(load-theme 'wombat)

;; Treat ~/.aliases as a shell script (syntax highlighting, indentation).
(add-to-list 'auto-mode-alist '("/\\.aliases\\'" . sh-mode))

(global-font-lock-mode 1) ; turn on syntax coloring
(show-paren-mode 1) ; turn on paren match highlighting
(setq show-paren-style 'expression) ; highlight entire bracket expression
(column-number-mode 1)

(add-to-list 'default-frame-alist '(width . 120)) ; character
(add-to-list 'default-frame-alist '(height . 40)) ; lines

;; Middle-click paste goes to the cursor, not to where the mouse points.
(setq mouse-yank-at-point t)

;; Enable this case-changing command without the "disabled command" prompt.
(put 'upcase-region 'disabled nil)

;; Skip the splash/startup screen and start with an empty *scratch* buffer.
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)

;; Keep Customize's state out of this tracked file: anything saved through
;; M-x customize goes to custom.el in the Emacs directory instead.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'noerror)

(when (fboundp 'tool-bar-mode) (tool-bar-mode -1)) ; no toolbar

;; Use the first available monospace font at 14pt, in preference order:
;; Consolas (Windows), Menlo (macOS), DejaVu Sans Mono (Linux), Courier New.
;; If none is found, keep the default font but still at 14pt.
(cond
 ((find-font (font-spec :name "Consolas")) (set-frame-font "Consolas-14" nil t))
 ((find-font (font-spec :name "Menlo")) (set-frame-font "Menlo-14" nil t))
 ((find-font (font-spec :name "DejaVu Sans Mono")) (set-frame-font "DejaVu Sans Mono-14" nil t))
 ((find-font (font-spec :name "Courier New")) (set-frame-font "Courier New-14" nil t))
 (t (set-face-attribute 'default nil :height 140)))

;; Remove duplicate lines in region (keeps first occurrence).
(defalias 'uniq-lines 'delete-duplicate-lines)

;; Enable this case-changing command without the "disabled command" prompt.
(put 'downcase-region 'disabled nil)
