;; Minimal Emacs config for pi-coding-agent
;; Pi + Wombat theme + Meow + WSL integration

;; Package setup
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install dependencies if missing
(dolist (pkg '(markdown-mode transient meow vertico orderless marginalia
               which-key embark embark-consult consult))
  (unless (package-installed-p pkg)
    (unless package-archive-contents (package-refresh-contents))
    (package-install pkg)))

;; Vertico - vertical completion UI
(require 'vertico)
(vertico-mode 1)

;; Orderless - flexible matching (space-separated patterns)
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion))))

;; Marginalia - rich annotations in completion
(require 'marginalia)
(marginalia-mode 1)

;; Which-key - show available keybindings
(require 'which-key)
(which-key-mode 1)
(setq which-key-idle-delay 0.5)  ; Show after 0.5s

;; Recentf - track recently opened files
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-saved-items 100)
(add-hook 'kill-emacs-hook 'recentf-save-list)

;; Start with bootstrap doc instead of scratch
(setq initial-buffer-choice "~/.emacs-bootstrap.md")

;; Embark - context actions (right-click-like menus)
(require 'embark)
;; Use M-. which works in all terminals and doesn't conflict with Meow
(global-set-key (kbd "M-.") 'embark-act)
(global-set-key (kbd "M-,") 'embark-dwim)

;; Consult - enhanced search and navigation
(require 'consult)
;; Don't override C-s globally (Meow uses it), add to leader instead
(global-set-key (kbd "C-x b") 'consult-buffer)        ; Better buffer switching
(global-set-key (kbd "M-g g") 'consult-goto-line)    ; Better goto-line
(global-set-key (kbd "M-y") 'consult-yank-pop)       ; Better yank-pop
(global-set-key (kbd "C-x p g") 'consult-ripgrep)    ; Project-wide search
(global-set-key (kbd "C-c f") 'consult-fd)           ; Find files with fd
(global-set-key (kbd "C-c o") 'other-window)          ; Switch window
;; In insert mode, C-s works for search
(define-key key-translation-map (kbd "C-s") (kbd "C-s"))

;; Dark theme - wombat (built-in)
(setq frame-background-mode 'dark)
(mapc 'frame-set-background-mode (frame-list))
(load-theme 'wombat t)

;; Layout management for pi-coding-agent
(defun pi--find-buffers ()
  "Find pi chat and input buffers in current frame.
Returns cons (CHAT-BUFFER . INPUT-BUFFER) or nil if not found."
  (let ((chat-buf nil)
        (input-buf nil))
    ;; Search all buffers for pi-coding-agent buffers
    (dolist (buf (buffer-list))
      (let ((name (buffer-name buf)))
        (when (string-match "^\\*pi-coding-agent-chat:" name)
          (setq chat-buf buf))
        (when (string-match "^\\*pi-coding-agent-input:" name)
          (setq input-buf buf))))
    (when (and chat-buf input-buf)
      (cons chat-buf input-buf))))

(defun pi-layout-default ()
  "Switch to default pi layout: chat on top, input on bottom."
  (interactive)
  (let ((buffers (pi--find-buffers)))
    (if buffers
        (let ((chat-buf (car buffers))
              (input-buf (cdr buffers)))
          ;; Delete all windows in current frame except one
          (delete-other-windows)
          ;; Set up default layout
          (switch-to-buffer chat-buf)
          (let ((input-win (split-window nil (- pi-coding-agent-input-window-height) 'below)))
            (set-window-buffer input-win input-buf)
            (select-window input-win)))
      (message "No pi-coding-agent session found"))))

(defun pi-layout-with-right-window ()
  "Switch to pi layout with extra full-height window on right."
  (interactive)
  (let ((buffers (pi--find-buffers)))
    (if buffers
        (let ((chat-buf (car buffers))
              (input-buf (cdr buffers)))
          ;; Delete all windows in current frame except one
          (delete-other-windows)
          ;; Split right first for full-height window
          (let ((right-win (split-window nil nil 'right)))
            ;; Now set up left side with chat/input split
            (switch-to-buffer chat-buf)
            (let ((input-win (split-window nil (- pi-coding-agent-input-window-height) 'below)))
              (set-window-buffer input-win input-buf)
              (select-window input-win))))
      (message "No pi-coding-agent session found"))))

;; Meow - modal editing (Kakoune-style)
(defun meow-setup ()
  "Set up meow with QWERTY layout."
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-motion-overwrite-define-key
   '("j" . meow-next)
   '("k" . meow-prev)
   '("<escape>" . ignore))
  (meow-leader-define-key
   '("o" . other-window)
   '("b" . switch-to-buffer)
   '("?" . meow-cheatsheet)
   '("." . embark-act)
   '("," . embark-dwim)
   ;; Consult commands
   '("s" . consult-line)
   '("f" . consult-fd)
   '("g" . consult-ripgrep)
   '("r" . consult-recent-file)
   ;; Windows integration (works in WSL and native Windows)
   '("w i" . win-paste-image)
   '("w p" . win-paste-text)
   '("w c" . win-copy-text)
   '("w e" . win-open-explorer)
   ;; Layout switching
   '("l 1" . pi-layout-default)
   '("l 2" . pi-layout-with-right-window)
   '("1" . meow-digit-argument)
   '("2" . meow-digit-argument)
   '("3" . meow-digit-argument)
   '("4" . meow-digit-argument)
   '("5" . meow-digit-argument)
   '("6" . meow-digit-argument)
   '("7" . meow-digit-argument)
   '("8" . meow-digit-argument)
   '("9" . meow-digit-argument)
   '("0" . meow-digit-argument))
  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("9" . meow-expand-9)
   '("8" . meow-expand-8)
   '("7" . meow-expand-7)
   '("6" . meow-expand-6)
   '("5" . meow-expand-5)
   '("4" . meow-expand-4)
   '("3" . meow-expand-3)
   '("2" . meow-expand-2)
   '("1" . meow-expand-1)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . meow-find)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("h" . meow-left)
   '("H" . meow-left-expand)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("j" . meow-next)
   '("J" . meow-next-expand)
   '("k" . meow-prev)
   '("K" . meow-prev-expand)
   '("l" . meow-right)
   '("L" . meow-right-expand)
   '("m" . meow-join)
   '("n" . meow-search)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("Q" . meow-goto-line)
   '("r" . meow-replace)
   '("R" . meow-swap-grab)
   '("s" . meow-kill)
   '("t" . meow-till)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)
   '("v" . meow-visit)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("'" . repeat)
   '("<escape>" . ignore)))

(require 'meow)
(meow-setup)
(setq meow-mode-state-list
      '((dired-mode . motion)
        (help-mode . motion)
        (Info-mode . motion)))
(meow-global-mode 1)

;; Load pi-coding-agent
(add-to-list 'load-path "~/.emacs.d/site-lisp/pi-coding-agent")
(require 'pi-coding-agent)

;; Shortcut: M-x pi to start
(defalias 'pi 'pi-coding-agent)

;; Clean startup
(setq inhibit-startup-screen t)

;; Platform detection
(defvar *is-wsl*
  (and (eq system-type 'gnu/linux)
       (string-match-p "microsoft\\|WSL"
                       (or (ignore-errors
                             (with-temp-buffer
                               (insert-file-contents "/proc/version")
                               (buffer-string)))
                           "")))
  "Non-nil if running in WSL.")

(defvar *is-windows* (eq system-type 'windows-nt)
  "Non-nil if running native Windows.")

;; Cross-platform Windows integration
(defun win-paste-text ()
  "Paste text from Windows clipboard."
  (interactive)
  (let ((text (cond
               (*is-wsl*
                (shell-command-to-string "powershell.exe -Command Get-Clipboard"))
               (*is-windows*
                (with-temp-buffer
                  (clipboard-yank)
                  (buffer-string))))))
    (when text
      (insert (string-trim-right text)))))

(defun win-copy-text ()
  "Copy region to Windows clipboard."
  (interactive)
  (when (use-region-p)
    (let ((text (buffer-substring-no-properties (region-beginning) (region-end))))
      (cond
       (*is-wsl*
        (let ((process-connection-type nil))
          (let ((proc (start-process "clip" nil "clip.exe")))
            (process-send-string proc text)
            (process-send-eof proc))))
       (*is-windows*
        (kill-new text)))
      (message "Copied to clipboard"))))

(defun win-paste-image ()
  "Insert path to most recent Windows screenshot."
  (interactive)
  (let* ((screenshots-glob
          (cond
           (*is-wsl* "/mnt/c/Users/*/Pictures/Screenshots/*.png")
           (*is-windows* "~/Pictures/Screenshots/*.png")))
         (screenshot
          (when screenshots-glob
            (car (sort (file-expand-wildcards screenshots-glob t)
                       (lambda (a b)
                         (time-less-p (nth 5 (file-attributes b))
                                      (nth 5 (file-attributes a)))))))))
    (if screenshot
        (progn (insert "\"" screenshot "\"")
               (message "Inserted: %s" screenshot))
      (message "No screenshots found"))))

(defun win-open-explorer ()
  "Open Windows Explorer at current directory."
  (interactive)
  (let ((dir (expand-file-name default-directory)))
    (cond
     (*is-wsl*
      (let ((winpath (string-trim
                      (shell-command-to-string
                       (concat "wslpath -w " (shell-quote-argument dir))))))
        (call-process "explorer.exe" nil nil nil winpath)))
     (*is-windows*
      (call-process "explorer.exe" nil nil nil (convert-standard-filename dir))))
    (message "Opening Explorer at %s" dir)))

