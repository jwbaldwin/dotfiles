;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "James Baldwin"
      user-mail-address "jwbaldwin3@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

(setq doom-theme 'doom-palenight
      doom-font (font-spec :family "DankMono Nerd Font" :size 16)
      doom-big-font (font-spec :family "DankMono Nerd Font" :size 16))

(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))

(setq doom-neotree-enable-variable-pitch nil)

(setq display-line-numbers-type t)

(setq org-directory "~/org/")

(setq evil-escape-key-sequence "kj")

;; Workaround to enable running credo after lsp
(defvar-local my/flycheck-local-cache nil)
(defun my/flycheck-checker-get (fn checker property)
  (or (alist-get property (alist-get checker my/flycheck-local-cache))
      (funcall fn checker property)))
(advice-add 'flycheck-checker-get :around 'my/flycheck-checker-get)
(add-hook 'lsp-managed-mode-hook
          (lambda ()
            (when (derived-mode-p 'elixir-mode)
              (setq my/flycheck-local-cache '((lsp . ((next-checkers . (elixir-credo)))))))
            ))

;; Reducde lsp compilation
(setq lsp-file-watch-ignored
      '(".idea" ".ensime_cache" ".eunit" "node_modules"
        ".git" ".hg" ".fslckout" "_FOSSIL_"
        ".bzr" "_darcs" ".tox" ".svn" ".stack-work"
        "build" "_build" "deps" "postgres-data")
      )

;; Format after save
(setq-hook! 'elixir-mode-hook +format-with-lsp nil)
(add-hook 'elixir-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'elixir-format nil t)))
(setq elixir-format-arguments (list "--dot-formatter" ".formatter.exs"))

;; Tabs configuration
(after! centaur-tabs
  :ensure t
  :config
   (setq centaur-tabs-style "bar"
         centaur-tabs-set-bar 'over
         centaur-tabs-set-icons t
         centaur-tabs-gray-out-icons 'buffer)
   (centaur-tabs-headline-match)
   (centaur-tabs-mode t))

;;
;; Keybinds
;;


(map! :leader
      :desc "Neotree"
      "e" #'+treemacs/toggle)

(map! :leader
      :desc "Find file in project"
      "." 'projectile-find-file)

;; Motion
(after! evil-easymotion
  (evil-define-key* '(motion normal) evil-snipe-local-mode-map "S" nil)
  (evil-define-key* '(motion normal) evil-snipe-local-mode-map "s" nil)
  (define-key evil-normal-state-map "S" nil)
  (evilem-default-keybindings "S"))

(map! :n "s" 'evil-avy-goto-char-2)
(map! :v "z" 'evil-avy-goto-char-2-below)
(map! :v "Z" 'evil-avy-goto-char-2-above)

;; optional, if you want to see the which key popup
(setq which-key-show-transient-maps t)

;; Tabs
(map!
 :n "H" 'centaur-tabs-backward
 :n "L" 'centaur-tabs-forward)

;; Harpoon
(map! :leader "j c" 'harpoon-clear)
(map! :leader "j f" 'harpoon-toggle-file)

(map! :n "C-h" 'harpoon-quick-menu-hydra)
(map! :n "C-f" 'harpoon-add-file)
(map! :n "C-j" 'harpoon-go-to-1)
(map! :n "C-k" 'harpoon-go-to-2)
(map! :n "C-l" 'harpoon-go-to-3)
(map! :n "C-;" 'harpoon-go-to-4)

;; elixir specific keybinds

;; unbind some stuff
(map! :after elixir-mode
      :map alchemist-mode-map
      :n "C-j" nil
      :n "C-k" nil)

(map! :after elixir-mode
      :map elixir-mode-map
      :n "C-j" nil
      :n "C-k" nil)

(map! :nv "gr" '+lookup/references)
(map! :nv "gR" 'xref-find-references)

(map! :after elixir-mode
      :localleader
      :map elixir-mode-map
      (:prefix ("i" . "iEx")
      :desc "iEx session" :n "i" #'alchemist-iex-start-process
      :desc "mix -S iEx session" :n "p" #'alchemist-iex-project-run))

(map! :after elixir-mode
      :map alchemist-mode-map
      :n "C-<up>" #'alchemist-goto-jump-to-previous-def-symbol)
(map! :after elixir-mode
      :map alchemist-mode-map
      :n "C-<down>" #'alchemist-goto-jump-to-next-def-symbol)

(map! :after elixir-mode
      :localleader
      :map alchemist-mode-map
      :desc "Alternate file" :nve "a" #'exunit-toggle-file-and-test
      :desc "Run module" :nve "m" #'exunit-verify
      :desc "Run single" :nve "s" #'exunit-verify-single
      :desc "Run last" :nve "l" #'exunit-rerun)

(map! :after elixir-mode
      :map elixir-mode-map
      :desc "Run debug"
       :nve "SPC m t d" #'exunit-debug)

(map! :after elixir-mode
      :map elixir-mode-map
      :desc "Run all tests"
       :nve "SPC m t a" #'exunit-verify-all)

(map! :after elixir-mode
      :map elixir-mode-map
      :desc "Make test file"
       :nve "SPC m t f" #'exunit-create-test-for-current-buffer)
