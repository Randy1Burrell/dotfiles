;;; init.el --- Load Randy's generated configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(let ((minimum-version "29.1"))
  (when (version< emacs-version minimum-version)
    (error "This configuration requires Emacs %s or newer" minimum-version)))

(setq custom-file (locate-user-emacs-file "custom.el")
      read-process-output-max (* 4 1024 1024)
      process-adaptive-read-buffering nil
      load-prefer-newer t)

(defconst *is-a-mac* (eq system-type 'darwin))

(defun system-is-mac ()
  "Return non-nil when Emacs is running on macOS."
  *is-a-mac*)

(defun system-is-linux ()
  "Return non-nil when Emacs is running on GNU/Linux."
  (eq system-type 'gnu/linux))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "custom" user-emacs-directory))

(require 'package)
(setq package-user-dir
      (expand-file-name
       (format "elpa-%s.%s" emacs-major-version emacs-minor-version)
       user-emacs-directory))
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package diminish :demand t)
(use-package bind-key :demand t)

(defun require-package (package &optional min-version no-refresh)
  "Install PACKAGE when absent, optionally requiring MIN-VERSION.
When NO-REFRESH is non-nil, do not refresh package metadata first."
  (or (package-installed-p package min-version)
      (progn
        (unless (or no-refresh package-archive-contents)
          (package-refresh-contents))
        (package-install package)
        t)))

(defun maybe-require-package (package &optional min-version no-refresh)
  "Try to install PACKAGE without aborting startup on failure."
  (condition-case err
      (require-package package min-version no-refresh)
    (error
     (message "Optional package %s was not installed: %s"
              package (error-message-string err))
     nil)))

(defgroup rb/emacs-config nil
  "Development helpers for Randy's literate Emacs configuration."
  :group 'convenience)

(defcustom rb/emacs-config-source nil
  "Optional path to the editable Emacs config.org file.
When nil, prefer the current config.org buffer, then DOTFILES_DIR, the
standard dotfiles checkout, and finally the deployed read-only copy."
  :type '(choice (const :tag "Discover automatically" nil) file)
  :group 'rb/emacs-config)

(defun rb/emacs-config--source-file ()
  "Return the best available literate Emacs source file."
  (let* ((dotfiles-root
          (or (getenv "DOTFILES_DIR")
              (expand-file-name "~/.local/share/src/dotfiles")))
         (checkout-source
          (expand-file-name
           "nix/modules/shared/config/emacs/config.org"
           dotfiles-root))
         (deployed-source (expand-file-name "~/.config/emacs/config.org")))
    (cond
     ((and buffer-file-name
           (string-equal (file-name-nondirectory buffer-file-name) "config.org"))
      buffer-file-name)
     ((and rb/emacs-config-source
           (file-readable-p rb/emacs-config-source))
      rb/emacs-config-source)
     ((file-readable-p checkout-source) checkout-source)
     ((file-readable-p deployed-source) deployed-source))))

(defun rb/emacs-config--required-modules (init-local)
  "Return the ordered init features required by INIT-LOCAL."
  (with-temp-buffer
    (insert-file-contents init-local)
    (let (modules)
      (goto-char (point-min))
      (while (re-search-forward
              "^[[:space:]]*(require[[:space:]]+'\\([^[:space:]()]+\\)"
              nil t)
        (push (intern (match-string 1)) modules))
      (nreverse modules))))

(defun rb/emacs-config--module-file (generated-home feature)
  "Find FEATURE below GENERATED-HOME, returning nil when it was not tangled."
  (let ((name (concat (symbol-name feature) ".el")))
    (seq-find
     #'file-readable-p
     (list (expand-file-name (concat "lisp/" name) generated-home)
           (expand-file-name (concat "custom/" name) generated-home)))))

(defun rb/tangle-and-reload-emacs-config (&optional source)
  "Tangle SOURCE in isolation and reload its selected init modules.
With a prefix argument, prompt for SOURCE.  Generated files are written below
a temporary HOME, so this command never modifies Nix-managed configuration."
  (interactive
   (list (when current-prefix-arg
           (read-file-name "Literate Emacs configuration: " nil nil t))))
  (require 'seq)
  (let* ((source (or source
                     (rb/emacs-config--source-file)
                     (and (called-interactively-p 'interactive)
                          (read-file-name
                           "Literate Emacs configuration: " nil nil t))))
         (source (and source (expand-file-name source))))
    (unless (and source (file-readable-p source))
      (user-error "No readable Emacs config.org source was found"))
    (when (and (get-file-buffer source)
               (buffer-modified-p (get-file-buffer source)))
      (user-error "Save %s before tangling" source))
    (let* ((scratch-home (make-temp-file "rb-emacs-config-" t))
           (generated-home (expand-file-name ".emacs.d" scratch-home))
           (init-local (expand-file-name "lisp/init-local.el" generated-home))
           (output-buffer (get-buffer-create "*Emacs config tangle*"))
           (emacs-binary (expand-file-name invocation-name invocation-directory)))
      (unwind-protect
          (progn
            (with-current-buffer output-buffer
              (erase-buffer))
            (unless (zerop
                     (let ((process-environment
                            (cons (concat "HOME=" scratch-home)
                                  process-environment)))
                       (call-process
                        emacs-binary nil output-buffer nil
                        "--batch" "--quick"
                        "--eval" "(require 'org)"
                        "--eval" (format "(org-babel-tangle-file %S)" source))))
              (display-buffer output-buffer)
              (error "Tangling failed; see %s" (buffer-name output-buffer)))
            (unless (file-readable-p init-local)
              (error "Tangling did not generate %s" init-local))
            (let ((modules (rb/emacs-config--required-modules init-local))
                  (loaded 0)
                  (load-path (append (list (expand-file-name "lisp" generated-home)
                                           (expand-file-name "custom" generated-home))
                                     load-path)))
              (dolist (feature modules)
                (when-let ((module-file
                            (rb/emacs-config--module-file generated-home feature)))
                  (load module-file nil 'nomessage)
                  (setq loaded (1+ loaded))))
              (message "Tangled %s and reloaded %d modules" source loaded)))
        (delete-directory scratch-home t)))))

(require 'init-local)

(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

(require 'init-preload-local nil t)
(require 'init-postload-local nil t)

(add-hook 'after-init-hook
          (lambda ()
            (require 'server)
            (unless (server-running-p)
              (server-start))))

(provide 'init)
;;; init.el ends here
