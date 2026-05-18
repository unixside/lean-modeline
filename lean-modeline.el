;; lean-modeline.el --- Minimal header-line for Emacs with customizable prefix icons
;;; -*- lexical-binding: t -*-
;;
;; Author: lean
;; Version: 0.1.0
;; Package-Requires: ((nerd-icons "0.1.0") (emacs "27.1") (cl-lib "1.0"))
;;
;;; Commentary:
;; This package provides a minimal header-line configuration for Emacs.
;; It replaces the traditional mode-line with a sleek header-line display.
;;
;; Features:
;;   - Customizable prefix with different rendering styles (nano, bespoke, nerd-icons)
;;   - Displays buffer name, VC branch, and cursor position
;;   - Visual indicators for buffer state (read-only, modified, normal)
;;   - Optional thin mode-line rendering
;;
;; Installation:
;;   (use-package lean-modeline
;;     :straight (lean-modeline :type git :host github :repo "lean/lean-modeline"))
;;   or manually place in load-path and (require 'lean-modeline)
;;
;; Basic Usage:
;;   (lean-modeline-mode 1)           ; Enable the mode globally
;;   (lean-modeline-mode -1)          ; Disable the mode
;;
;; Customization:
;;   M-x customize-group RET lean-modeline RET
;;
;; Prefix Styles:
;;   - 'lean/nano-ui-prefix        : Text-based prefix (RO/**/RW) with SVG background
;;   - 'lean/bespoke-ui-prefix     : Circle characters (◯/⨀/⨂) with SVG background
;;   - 'lean/header-line-nerd-icon-prefix : Nerd Fonts icon for current buffer type
;;
;;   Example: (setq lean-modeline-prefix-function 'lean/bespoke-ui-prefix)
;;
;; Thin Mode-Line:
;;   (lean/thin-mode-line)  ; Call to flatten the standard mode-line to a thin line
;;
;;; Code:
(require 'svg)
(require 'cl-lib)
(require 'nerd-icons)

(defgroup lean-modeline nil
  "Lean modeline configuration."
  :group 'modeline)

(defcustom lean-modeline-icon-scale-factor 1.2
  "Scale factor for icons in the header-line prefix.
This value multiplies the base font size when rendering icon-based
prefixes such as `lean/header-line-nerd-icon-prefix' and
`lean/bespoke-ui-prefix'. Higher values produce larger icons."
  :type 'float
  :group 'lean-modeline)

(defcustom lean-modeline-text-scale-factor 1.1
  "Scale factor for text elements in the header-line.
This value multiplies the base font size for text components such as
buffer name, mode name, cursor position, and VC branch information.
Used by `lean/nano-ui-prefix' and all text rendering functions."
  :type 'float
  :group 'lean-modeline)

(defcustom lean-modeline-prefix-padding 2.0
  "Additional padding around the header-line prefix element.
This value is added to the font size when calculating the total width
and height of SVG-based prefix elements (nano and bespoke styles).
Increase for more spacing, decrease for a more compact display."
  :type 'float
  :group 'lean-modeline)

(defcustom lean-modeline-prefix-function 'lean/nano-ui-prefix
  "Function used to render the header-line prefix.
This function is called to produce the leftmost element of the
header-line, which displays buffer state information.

Available built-in functions:
  - `lean/nano-ui-prefix'      : Text-based (RO/**/RW) with inverted colors
  - `lean/bespoke-ui-prefix'   : Circle characters (◯/⨀/⨂) with inverted colors
  - `lean/header-line-nerd-icon-prefix' : Nerd Fonts icon matching buffer type

Custom functions should accept no arguments and return a string or
image suitable for display in the header-line."
  :type 'function
  :group 'lean-modeline)

(defun lean/get-prefix-inherit-face ()
  "Compute the face for the header-line prefix based on buffer state.
Returns a face property list with foreground and background colors
inverted based on the current buffer's read-only or modified status.

- Read-only buffer: uses 'success face colors
- Modified buffer: uses 'error face colors
- Normal buffer: uses 'default face colors

The returned value is a plist suitable for use in face properties."
  (let* ((face
          (cond
           (buffer-read-only
            'success)
           ((buffer-modified-p)
            'error)
           (t
            'default)))
         (foreground (face-foreground face))
         (background
          (or (face-background face)
              (face-background 'header-line)
              (face-background 'default)))
         (face
          `(:background
            ,background
            :foreground ,foreground
            :box nil
            :underline nil
            :overline nil)))
    face))

(defun lean/get-nano-prefix ()
  "Return the text prefix for nano-style rendering.
Returns a string indicating the current buffer's state:
  - \" RO \" when the buffer is read-only
  - \" ** \" when the buffer has unsaved changes
  - \" RW \" for a normal read-write buffer with no modifications"
  (cond
   (buffer-read-only
    " RO ")
   ((buffer-modified-p)
    " ** ")
   (t
    " RW ")))

(defun lean/get-terminal-prefix ()
  "Return the terminal-style prefix string with appropriate face.
This function is used when Emacs is running in a non-graphical
terminal. It renders the nano-style prefix (RO/**/RW) with inverse
video styling and scaled font size for better visibility."
  (let ((prefix (lean/get-nano-prefix))
        (face (lean/get-prefix-inherit-face)))
    (propertize prefix
                'face
                `(:inherit
                  ,face
                  :inverse-video t
                  :height ,lean-modeline-text-scale-factor))))

(defun lean/get-nerd-icon-for-buffer ()
  "Get icon for buffer with nerd-icons function."
  (let ((icon (substring-no-properties (nerd-icons-icon-for-buffer))))
    (if icon
        icon
      #xe632)))

(defun lean/create-and-render-svg-image (&rest args)
  "Create and render svg image with `ARGS'."
  (let* ((icon (plist-get args :icon))
         (text (plist-get args :text))
         (foreground (plist-get args :foreground))
         (background (plist-get args :background))
         (font (plist-get args :font))
         (font-size (plist-get args :font-size))
         (width (plist-get args :width))
         (height (plist-get args :height))
         (svg (svg-create width height)))
    (setq-local prefix (or text icon))
    (svg-rectangle
     svg
     0
     0
     width
     height
     :fill background
     :stroke background)
    (svg-text
     svg
     prefix
     :font-family font
     :font-size font-size
     :fill foreground
     :x (/ width 2.0)
     :y (/ height 2.0)
     :text-anchor "middle"
     :dominant-baseline "central")
    (propertize " " 'display (svg-image svg :ascent 'center))))

(defun lean/header-line-nerd-icon-prefix ()
  "Render the header-line prefix using a Nerd Fonts icon.
Uses `nerd-icons-icon-for-buffer' to select an appropriate icon
matching the current buffer's major mode (e.g.,.el for Emacs Lisp,
.org for Org mode, etc.). Returns an SVG image with the icon centered
on a background matching the current buffer state colors."
  (let* ((face       (lean/get-prefix-inherit-face))
         (foreground      (plist-get face-plist :foreground))
         (background (plist-get face-plist :background))
         (icon (lean/get-nerd-icon-for-buffer))
         (font-size (font-get (face-attribute 'default :font) :size))
         (width (* font-size 2.1 lean-modeline-icon-scale-factor))
         (height (* font-size 2.05 lean-modeline-icon-scale-factor)))
    (lean/create-and-render-svg-image
     :icon icon
     :text nil
     :foreground foreground
     :background background
     :font nerd-icons-font-family
     :font-size font-size
     :width width
     :height height)))

(defun lean/char-bespoke-prefix ()
  "Return the circle character prefix for bespoke-style rendering.
Returns a Unicode circle symbol indicating the current buffer's state:
  - \" ⨂ \" (circled asterisk) when the buffer is read-only
  - \" ⨀ \" (bulleted circle) when the buffer has unsaved changes
  - \" ◯ \" (white circle) for a normal read-write buffer"
  (cond
   (buffer-read-only
    " ⨂ ")
   ((buffer-modified-p)
    " ⨀ ")
   (t
    " ◯ ")))
      
(defun lean/bespoke-ui-prefix ()
  "Render the bespoke-style prefix as an SVG image.
Creates a square SVG containing a circle character that indicates
the buffer's state (read-only/modified/normal). The icon uses inverted
colors from the current face - background becomes foreground and vice
versa. This creates a distinctive visual style similar to nanoUi's
header-line appearance."
  (let* ((face (lean/get-prefix-inherit-face))
         (foreground (plist-get face :background))
         (background (plist-get face :foreground))
         (font (face-attribute 'default :font))
         (font-size
          (* (font-get font :size) lean-modeline-icon-scale-factor))
         (size (+ font-size (* 8 lean-modeline-prefix-padding))))
    (lean/create-and-render-svg-image
     :icon nil
     :text (lean/char-bespoke-prefix)
     :foreground foreground
     :background background
     :font
     (face-attribute 'default :family)
     :font-size font-size
     :width size
     :height size)))

(defun lean/nano-ui-prefix ()
  "Render the nano-style prefix as an SVG image.
Creates a square SVG containing the nano-style text prefix (RO/**/RW)
that indicates the buffer's state. Uses inverted colors from the
current face for high contrast. This is the default prefix rendering
function and provides a clean, minimal appearance."
  (let* ((face (lean/get-prefix-inherit-face))
         (foreground (plist-get face :background))
         (background (plist-get face :foreground))
         (font (face-attribute 'default :font))
         (font-size
          (* (font-get font :size) lean-modeline-text-scale-factor))
         (size (+ font-size (* 8 lean-modeline-prefix-padding))))
    (lean/create-and-render-svg-image
     :icon nil
     :text (lean/get-nano-prefix)
     :foreground foreground
     :background background
     :font
     (face-attribute 'default :family)
     :font-size font-size
     :width size
     :height size)))

(defun lean/header-line-right-align (reserve-area)
  "Insert right-aligning whitespace in the header-line.
RESERVE-AREA is the number of character positions to reserve for the
rightmost element (typically the cursor position display). This
ensures the right-side content stays aligned to the edge of the
window regardless of the prefix and buffer name width."
  (propertize " "
              'face
              '(:inherit header-line)
              'display
              `(space :align-to (- right ,reserve-area))))

(defun lean/header-line-buffer-name ()
  "Renderer for header-line buffer name."
  (let* ((buffer-name
          (if (and buffer-file-name
                   (< (length buffer-file-name) (/ (window-width) 2)))
              (abbreviate-file-name buffer-file-name)
            (buffer-name)))
         (buffer-name (format " %s " buffer-name)))
    (propertize buffer-name
                'face
                `(:inherit
                  header-line
                  :weight bold
                  :slant italic
                  :height ,lean-modeline-text-scale-factor))))

(defun lean/header-line-buffer-mode ()
  "Renderer `mode-name' from current buffer."
  (let* ((mode
          (format "(%s)"
                  (substring-no-properties
                   (format-mode-line mode-name)))))
    (propertize mode
                'face
                `(:inherit
                  shadow
                  :slant italic
                  :weight light
                  :height ,lean-modeline-text-scale-factor))))

(defun lean/header-line-cursor-position ()
  "Renderer current coordinates of cursor."
  (propertize (format-mode-line "%c:%l ")
              'face
              `(:inherit
                font-lock-comment-face
                :slant italic
                :weight regular
                :height ,lean-modeline-text-scale-factor)))

(defun lean/header-line-vc-branch ()
  "Render the version control branch information in the header-line.
Extracts the current branch name from `vc-mode' and displays it with
a Git branch icon () . Returns a space character if the buffer is
not under version control or if no branch information is available."
  (let ((branch
         (when vc-mode
           (cadr (string-split (substring-no-properties vc-mode) ":")))))
    (if branch
        (propertize (format " %s %s " "" branch)
                    'face
                    `(:inherit
                      font-lock-comment-face
                      :weight light
                      :slant normal
                      :height ,lean-modeline-text-scale-factor))
      (char-to-string ?\s))))

(defun lean/header-line-format ()
  "Renderer format for header-line."
  (let* ((prefix-format
          (if (display-graphic-p)
              (funcall lean-modeline-prefix-function)
            (lean/get-terminal-prefix)))
         (position (lean/header-line-cursor-position))
         (reserve
          (* (length position) lean-modeline-text-scale-factor)))
    (concat
     prefix-format
     (lean/header-line-buffer-name)
     (lean/header-line-vc-branch)
     (lean/header-line-right-align reserve)
     position)))

(defun lean/thin-mode-line ()
  "Renderer mode-line as thin line."
  (interactive)
  (setq-default mode-line-format (list ""))
  (if (display-graphic-p)
      (progn
        (custom-set-faces
         '(mode-line ((t (:inverse-video t :box nil :height 0.1))))
         '(mode-line-active
           ((t (:inverse-video t :box nil :height 0.1))))
         '(mode-line-inactive ((t (:box nil :height 0.1))))))
    (set-face-background 'mode-line "unspecified-bg")
    (set-face-background 'mode-line-active "unspecified-bg")
    (set-face-background 'mode-line-inactive "unspecified-bg")))

(define-minor-mode lean-modeline-mode
  "Toggle Lean Modeline mode.
This minor mode replaces the default mode-line with a custom
header-line that displays buffer information in a minimal style.

The header-line shows:
  - Prefix: buffer state (RO/**/RW) or mode icon
  - Buffer name: file name or buffer name
  - VC branch: git branch (if under version control)
  - Cursor position: column:line

When enabled, sets `header-line-format' to a custom eval form.
When disabled, restores header-line to nil.

Key binding: (bound in `global-map')
  \\[lean-modeline-mode] - toggle the mode"
  :global t
  :init-value
  nil
  (if lean-modeline-mode
      (setq-default header-line-format
                    '(:eval (lean/header-line-format)))
    (setq-default header-line-format nil)))

(provide 'lean-modeline)
;;; lean-modeline.el ends here
