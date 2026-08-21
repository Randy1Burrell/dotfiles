;;; early-init.el --- Settings applied before package and GUI startup -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(setq package-enable-at-startup nil
      frame-inhibit-implied-resize t
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 100 1024 1024)
                  gc-cons-percentage 0.1)))

(provide 'early-init)
;;; early-init.el ends here
