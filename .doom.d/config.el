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

;; ===========================
;;
;; Doom config
;;
;; ===========================

(setq doom-theme 'doom-moonlight-ii
      doom-font (font-spec :family "DankMono Nerd Font" :size 16)
      doom-big-font (font-spec :family "DankMono Nerd Font" :size 16))

;; Set line height and center the text in the new line height
(setq-default default-text-properties '(line-spacing 0.25 line-height 1.25))

(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))

(setq doom-neotree-enable-variable-pitch nil)

(setq display-line-numbers-type t)

(setq org-directory "~/org/")

(setq evil-escape-key-sequence "kj")

;; ===========================
;;
;; Dashboard
;;
;; ===========================

(setq +doom-dashboard-banner-dir "~/.doom.d/banners/"
      +doom-dashboard-banner-file "black-hole.png"
      +doom-dashboard-banner-padding '(0 . 5)
      +doom-dashboard--width 100)

(setq +doom-dashboard-menu-sections
  '(("Explore"
     :icon (all-the-icons-octicon "search" :height 0.75 :face 'doom-dashboard-menu-title)
     :action find-file)
    ("Recents"
     :icon (all-the-icons-octicon "history" :height 0.75 :face 'doom-dashboard-menu-title)
     :action recentf-open-files)
    ("Restore"
     :icon (all-the-icons-octicon "light-bulb" :height 0.75 :face 'doom-dashboard-menu-title)
     :when (cond ((featurep! :ui workspaces)
                  (file-exists-p (expand-file-name persp-auto-save-fname persp-save-dir)))
                 ((require 'desktop nil t)
                  (file-exists-p (desktop-full-file-name))))
     :face (:inherit (doom-dashboard-menu-title bold))
     :action doom/quickload-session)
    ("Projects"
     :icon (all-the-icons-octicon "repo" :height 0.75 :face 'doom-dashboard-menu-title)
     :action projectile-switch-project)
    ("Config"
     :icon (all-the-icons-octicon "settings" :height 0.75 :face 'doom-dashboard-menu-title)
     :when (file-directory-p doom-private-dir)
     :action doom/open-private-config)))

(remove-hook '+doom-dashboard-functions 'doom-dashboard-widget-footer)
(remove-hook '+doom-dashboard-functions 'doom-dashboard-widget-loaded)

;; ===========================
;;
;; General plugin config
;;
;; ===========================

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

;; Reduce lsp compilation
(setq lsp-file-watch-ignored
      '(".idea" ".ensime_cache" ".eunit" "node_modules"
        ".git" ".hg" ".fslckout" "_FOSSIL_"
        ".bzr" "_darcs" ".tox" ".svn" ".stack-work"
        "build" "_build" "deps" "postgres-data")
      )
(setq lsp-elixir-suggest-specs nil)
(setq lsp-elixir-mix-env "dev")
(setq lsp-elixir-dialyzer-enabled nil)
(setq lsp-elixir-signature-after-complete nil)


;; Add known projects

;; ===========================
;;
;; Keybinds
;;
;; ===========================


(map! :leader
      :desc "Neotree"
      "e" #'+treemacs/toggle)

(map! :leader
      :desc "Find file in project"
      "." 'projectile-find-file)

(map! :leader
      :desc "Dashboard"
      "d" #'+doom-dashboard/open)

(map! :after alchemist-mode :map alchemist-mode-map :ni "C-t" nil)
(map! :map evil-normal-state-map :ni "C-t" nil)
(map! :after alchemist-mode :map alchemist-mode-map :n "gb" #'alchemist-goto-jump-back)
(map! :after alchemist-mode :map alchemist-mode-map :ni "C-t" '+vterm/toggle)
(map! :ni "C-t" '+vterm/toggle)

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

;; unbind some stuff
(map! :after alchemist-mode :map alchemist-mode-map :n "C-j" nil)
(map! :after alchemist-mode :map alchemist-mode-map :n "C-k" nil)

(map! :after alchemist :map alchemist-mode-map :n "C-j" nil)
(map! :after alchemist :map alchemist-mode-map :n "C-k" nil)

(map! :after elixir-mode
      :map elixir-mode-map
      :n "C-j" nil
      :n "C-k" nil)

;; Harpoon
(map! :leader "j c" 'harpoon-clear)
(map! :leader "j f" 'harpoon-toggle-file)

(map! :n "C-h" 'harpoon-quick-menu-hydra)
(map! :n "C-f" 'harpoon-add-file)
(map! :n "C-j" 'harpoon-go-to-1)
(map! :n "C-k" 'harpoon-go-to-2)
(map! :n "C-l" 'harpoon-go-to-3)
(map! :n "C-;" 'harpoon-go-to-4)

;; Creates a function to edit my .aliases directory
(defvar personal-dotfiles-dir (expand-file-name "~/.aliases/"))

(defun personal/open-dotfiles ()
  "Browse my personal dotfiles under `personal-dotfiles-dir`."
  (interactive)
  (doom-project-browse personal-dotfiles-dir))

(map! :leader
      :prefix-map ("f" . "file")
      :desc "Browse personal dotfiles" "." #'personal/open-dotfiles
      )

;; Git blame stuff
(map! :leader
      :map global-blamer-mode
      :desc "Toggle blamer mode"
      :nve "g b" #'blamer-mode)

(map! :leader
      :map global-blamer-mode
      :desc "Push to upstream branch"
      :nve "g p" #'magit-push-current-to-upstream)

(map! :leader
      :map global-blamer-mode
      :desc "Checkout branch"
      :nve "g B" #'magit-branch-checkout)
(use-package blamer
  :defer 20
  :custom
        (blamer-author-formatter " ✎ %s ")
        (blamer-datetime-formatter "[%s]")
        (blamer-commit-formatter " • %s")
        (blamer-prettify-time-p t)
        (blamer-idle-time 0.3)
        (blamer-min-offset 30)
  :config
        (global-blamer-mode 0))
(setq blamer-view 'overlay-right)

(use-package polymode
  :mode ("\.ex$" . poly-elixir-web-mode)
  :config
  (define-hostmode poly-elixir-hostmode :mode 'elixir-mode)
  (define-innermode poly-liveview-expr-elixir-innermode
    :mode 'web-mode
    :head-matcher (rx line-start (* space) "~H" (= 3 (char "\"'")) line-end)
    :tail-matcher (rx line-start (* space) (= 3 (char "\"'")) line-end)
    :head-mode 'host
    :tail-mode 'host
    :allow-nested nil
    :keep-in-mode 'host
    :fallback-mode 'host)
  (define-polymode poly-elixir-web-mode
    :hostmode 'poly-elixir-hostmode
    :innermodes '(poly-liveview-expr-elixir-innermode))
  )
(setq web-mode-engines-alist '(("elixir" . "\\.ex\\'")))

;; elixir specific keybinds
(map! :nv "gr" '+lookup/references)
(map! :nv "gR" 'xref-find-references)

(map! :after elixir-mode
      :localleader
      :map elixir-mode-map
      (:prefix ("i" . "iEx")
      :desc "iEx session" :n "i" #'alchemist-iex-run
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

(map! :map doom-leader-code-map
      :desc "Peek inline docs" "h" #'lsp-ui-doc-glance)
