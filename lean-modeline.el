;; Package-Requires: ((nerd-icons "0.1.0") (emacs "27.1"))

(require 'svg)
(require 'nerd-icons)

(defun lean/get-prefix-inherit-face ()
  (cond (buffer-read-only    'font-lock-comment-face)
        ((buffer-modified-p) 'error)
        (t                   'default)))

(defun lean/header-line-nerd-icon-prefix ()
  (let* ((face (lean/get-prefix-inherit-face))
         (color (face-foreground face))
         (background (face-background 'header-line))
         (icon (substring-no-properties (nerd-icons-icon-for-buffer)))
         (icon (or icon #xe632))
         (font-size (font-get (face-attribute 'default :font) :size))
         (width (* font-size 2.1))
         (height (* font-size 2.05))
         (svg (svg-create width height)))
    ;; transparent svg 
    (svg-rectangle svg 0 0 width height :fill background :stroke background)
    (svg-text svg icon
              :font-family nerd-icons-font-family
              :font-size (* font-size 1.5)
              :fill color
              :x (/ width 2.0)
              :y (/ height 2.0)
              :text-anchor "middle"
              :dominant-baseline "central")
    (propertize " " 'display (svg-image svg :ascent 'center))))

(defun lean/header-line-right-align (reserve-area)
  "TODO: docstring"
  (propertize " " 'face '(:inherit header-line)
              'display `(space :align-to (- right ,reserve-area))))

(defun lean/header-line-buffer-name ()
  "Renderer for header-line `buffer-file-name' or `buffer-name'"
  (let* ((buffer-name (if (and buffer-file-name
                               (< (length buffer-file-name) (/ (window-width) 2)))
                          (abbreviate-file-name buffer-file-name)
                        (buffer-name))))
    (propertize buffer-name
                'face '(:inherit header-line :weight bold :slant italic))))

(defun lean/header-line-buffer-mode ()
  "Renderer `mode-name' from current buffer."
  (let* ((mode (format "(%s)" (substring-no-properties
                               (format-mode-line mode-name)))))
    (propertize mode 'face '(:inherit shadow :slant italic :weight light))))

(defun lean/header-line-cursor-position ()
  "Renderer current coordinates of cursor."
  (propertize (format-mode-line "%c:%l ")
              'face '(:inherit font-lock-comment-face
                               :slant italic :weight regular)))

(defun lean/header-line-vc-branch ()
  "TODO: docstring."
  (let ((branch (when vc-mode (substring-no-properties vc-mode))))
    (if branch
        (propertize branch 'face '(:inherit font-lock-comment-face
                                            :weight light :slant normal))
      (char-to-string ?\s))))

(defun lean/header-line-format ()
  "Renderer format for header-line"
  (let* ((position (lean/header-line-cursor-position))
         (reserve (length position)))
    (concat (lean/header-line-nerd-icon-prefix)
            (lean/header-line-buffer-name)
            (lean/header-line-vc-branch)
            (lean/header-line-right-align reserve)
            position)))

(defun lean/thin-mode-line ()
  "Renderer mode-line as thin line."
  (interactive)
  (setq-default mode-line-format (list ""))
  (custom-set-faces
   '(mode-line ((t (:inverse-video t :box nil :height 0.1))))
   '(mode-line-active ((t (:inverse-video t :box nil :height 0.1))))
   '(mode-line-inactive ((t (:box nil :height 0.1))))))

(define-minor-mode lean-modeline-mode
  "Minor mode for haeder-line."
  :global t
  :init-value nil
  (if lean/header-line-mode
      (setq-default header-line-format '(:eval (lean/header-line-format)))
    (setq-default header-line-format nil)))

(provide 'lean-modeline)
