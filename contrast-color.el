;;; contrast-color.el --- Pick best contrast color for you -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Yuta Yamada

;; Author: Yuta Yamada <cokesboy[at]gmail.com>
;; URL: https://github.com/yuutayamada/contrast-color-el
;; Version: 1.0.0
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: color, convenience

;;; The MIT License (MIT)

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; This package only provide a single function that return a contrast
;; color using CIEDE2000 algorithm.
;;
;;
;; Usage:
;;
;;   (contrast-color "#ff00ff") ; -> "#4caf50"
;;
;;                  or
;;
;;   (contrast-color "Brightmagenta") ; -> "#4caf50"
;;
;;
;; Note that if you want to choose from more colors, below configuration set
;; material design’s colors as color candidates:
;;
;;    (setq contrast-color-candidates contrast-color-material-colors
;;          contrast-color--lab-cache nil)
;;
;; But keep in mind that this configuration may increase calculation time.
;;
;;; Code:

(require 'color)
(require 'cl-lib)

(defgroup contrast-color nil "contrast-color group"
  :group 'convenience)

(defcustom contrast-color-candidates
  '("black" "white" "red" "green" "yellow" "blue" "magenta" "cyan")
  "List of colors.  One of those colors is used as the contrast color."
  :group 'contrast-color
  :type '(repeat :tag "list of colors" string))

;; TODO: make this variable saves when users exit Emacs, so don’t need
;; same calculation again.
(defcustom contrast-color-cache nil
  "Alist of specified base color and contrast color."
  :group 'contrast-color
  :type '(choice
          (const :tag "Initial value" nil)
          (repeat :tag "Cons sell of specified color and contrast color"
                  (cons string string))))

(defcustom contrast-color-use-hex-name t
  "If non-nil, returned color name will be hex value."
  :group 'contrast-color
  :type 'bool)

(defvar contrast-color--lab-cache nil
  "Internal cache.")

;;;;;;;;;;;;;;;;
;; Functions

(defun contrast-color--get-lab (color)
  "Get CIE l*a*b from COLOR."
  (apply 'color-srgb-to-lab (color-name-to-rgb color)))

(defun contrast-color--compute-core (base-color)
  "Return alist of (color-of-candidate . ciede2000).
As the reference BASE-COLOR will be used to compare on the process."
  (let* ((candidates contrast-color-candidates)
         (b (contrast-color--get-lab base-color))
         (labs-and-colors
          (or contrast-color--lab-cache
              (setq contrast-color--lab-cache
                    (cl-mapcar
                     (lambda (c) (cons (contrast-color--get-lab c) c)) candidates)))))
    (cl-loop for (l . c) in labs-and-colors
             collect (contrast-color--examine b l c))))

;; TODO: add an advice to debug distance
(defun contrast-color--examine (color1 color2 color2-name)
  "Examine distance of COLOR1 and COLOR2.
Return pair of (color-distance . COLOR2-NAME)."
  (cons (color-cie-de2000 color1 color2) color2-name))

(defun contrast-color--compute (color)
  "Return contrast color against COLOR."
  (cl-loop
   with cie-and-colors = (contrast-color--compute-core color)
   for (cie . c) in cie-and-colors
   for best = (cons cie c) then (if (< (car best) cie) (cons cie c) best)
   finally return (cdr best)))

;;;###autoload
(defun contrast-color (color)
  "Return most contrasted color against COLOR.
The return color picked from ‘contrast-color-candidates’.
The algorithm is used CIEDE2000. See also ‘color-cie-de2000’ function."
  (let ((cached-color (assoc-default color contrast-color-cache)))
    (if cached-color
        cached-color
      (let ((c (contrast-color--format (contrast-color--compute color))))
          (add-to-list 'contrast-color-cache (cons color c))
          c))))

(defun contrast-color--format (color)
  "Format color name.
If ‘contrast-color-use-hex-name’ is non-nil, convert COLOR name to hex form."
  (if (and contrast-color-use-hex-name
           (not (eq ?# (string-to-char color))))
      (apply 'color-rgb-to-hex (color-name-to-rgb color))
    color))

;; FIXME: defaulting this value would increase calculation time
;; https://material.google.com/style/color.html
;; license: http://zavoloklom.github.io/material-design-color-palette/license.html
(defconst contrast-color-material-colors
  '(; reds
    "#FFEBEE"
    "#FFCDD2"
    "#EF9A9A"
    "#E57373"
    "#EF5350"
    "#F44336"
    "#E53935"
    "#D32F2F"
    "#C62828"
    "#B71C1C"
    "#FF8A80"
    "#FF5252"
    "#FF1744"
    "#D50000"
    ;; pinks
    "#FCE4EC"
    "#F8BBD0"
    "#F48FB1"
    "#F06292"
    "#EC407A"
    "#E91E63"
    "#D81B60"
    "#C2185B"
    "#AD1457"
    "#880E4F"
    "#FF80AB"
    "#FF4081"
    "#F50057"
    "#C51162"
    ;; purples
    "#F3E5F5"
    "#E1BEE7"
    "#CE93D8"
    "#BA68C8"
    "#AB47BC"
    "#9C27B0"
    "#8E24AA"
    "#7B1FA2"
    "#6A1B9A"
    "#4A148C"
    "#EA80FC"
    "#E040FB"
    "#D500F9"
    "#AA00FF"
    ;; deep purple
    "#EDE7F6"
    "#D1C4E9"
    "#B39DDB"
    "#9575CD"
    "#7E57C2"
    "#673AB7"
    "#5E35B1"
    "#512DA8"
    "#4527A0"
    "#311B92"
    "#B388FF"
    "#7C4DFF"
    "#651FFF"
    "#6200EA"
    ;; indigo
    "#E8EAF6"
    "#C5CAE9"
    "#9FA8DA"
    "#7986CB"
    "#5C6BC0"
    "#3F51B5"
    "#3949AB"
    "#303F9F"
    "#283593"
    "#1A237E"
    "#8C9EFF"
    "#536DFE"
    "#3D5AFE"
    "#304FFE"
    ;; blue
    "#E3F2FD"
    "#BBDEFB"
    "#90CAF9"
    "#64B5F6"
    "#42A5F5"
    "#2196F3"
    "#1E88E5"
    "#1976D2"
    "#1565C0"
    "#0D47A1"
    "#82B1FF"
    "#448AFF"
    "#2979FF"
    "#2962FF"
    ;; light blue
    "#E1F5FE"
    "#B3E5FC"
    "#81D4fA"
    "#4fC3F7"
    "#29B6FC"
    "#03A9F4"
    "#039BE5"
    "#0288D1"
    "#0277BD"
    "#01579B"
    "#80D8FF"
    "#40C4FF"
    "#00B0FF"
    "#0091EA"
    ;; cyan
    "#E0F7FA"
    "#B2EBF2"
    "#80DEEA"
    "#4DD0E1"
    "#26C6DA"
    "#00BCD4"
    "#00ACC1"
    "#0097A7"
    "#00838F"
    "#006064"
    "#84FFFF"
    "#18FFFF"
    "#00E5FF"
    "#00B8D4"
    ;; teal
    "#E0F2F1"
    "#B2DFDB"
    "#80CBC4"
    "#4DB6AC"
    "#26A69A"
    "#009688"
    "#00897B"
    "#00796B"
    "#00695C"
    "#004D40"
    "#A7FFEB"
    "#64FFDA"
    "#1DE9B6"
    "#00BFA5"
    ;; green
    "#E8F5E9"
    "#C8E6C9"
    "#A5D6A7"
    "#81C784"
    "#66BB6A"
    "#4CAF50"
    "#43A047"
    "#388E3C"
    "#2E7D32"
    "#1B5E20"
    "#B9F6CA"
    "#69F0AE"
    "#00E676"
    "#00C853"
    ;; light green
    "#F1F8E9"
    "#DCEDC8"
    "#C5E1A5"
    "#AED581"
    "#9CCC65"
    "#8BC34A"
    "#7CB342"
    "#689F38"
    "#558B2F"
    "#33691E"
    "#CCFF90"
    "#B2FF59"
    "#76FF03"
    "#64DD17"
    ;; lime
    "#F9FBE7"
    "#F0F4C3"
    "#E6EE9C"
    "#DCE775"
    "#D4E157"
    "#CDDC39"
    "#C0CA33"
    "#A4B42B"
    "#9E9D24"
    "#827717"
    "#F4FF81"
    "#EEFF41"
    "#C6FF00"
    "#AEEA00"
    ;; yellow
    "#FFFDE7"
    "#FFF9C4"
    "#FFF590"
    "#FFF176"
    "#FFEE58"
    "#FFEB3B"
    "#FDD835"
    "#FBC02D"
    "#F9A825"
    "#F57F17"
    "#FFFF82"
    "#FFFF00"
    "#FFEA00"
    "#FFD600"
    ;; amber
    "#FFF8E1"
    "#FFECB3"
    "#FFE082"
    "#FFD54F"
    "#FFCA28"
    "#FFC107"
    "#FFB300"
    "#FFA000"
    "#FF8F00"
    "#FF6F00"
    "#FFE57F"
    "#FFD740"
    "#FFC400"
    "#FFAB00"
    ;; orange
    "#FFF3E0"
    "#FFE0B2"
    "#FFCC80"
    "#FFB74D"
    "#FFA726"
    "#FF9800"
    "#FB8C00"
    "#F57C00"
    "#EF6C00"
    "#E65100"
    "#FFD180"
    "#FFAB40"
    "#FF9100"
    "#FF6D00"
    ;; deep orange
    "#FBE9A7"
    "#FFCCBC"
    "#FFAB91"
    "#FF8A65"
    "#FF7043"
    "#FF5722"
    "#F4511E"
    "#E64A19"
    "#D84315"
    "#BF360C"
    "#FF9E80"
    "#FF6E40"
    "#FF3D00"
    "#DD2600"
    ;; brown
    "#EFEBE9"
    "#D7CCC8"
    "#BCAAA4"
    "#A1887F"
    "#8D6E63"
    "#795548"
    "#6D4C41"
    "#5D4037"
    "#4E342E"
    "#3E2723"
    ;; grey
    "#FAFAFA"
    "#F5F5F5"
    "#EEEEEE"
    "#E0E0E0"
    "#BDBDBD"
    "#9E9E9E"
    "#757575"
    "#616161"
    "#424242"
    "#212121"
    ;; blue grey
    "#ECEFF1"
    "#CFD8DC"
    "#B0BBC5"
    "#90A4AE"
    "#78909C"
    "#607D8B"
    "#546E7A"
    "#455A64"
    "#37474F"
    "#263238"
    ;; Black and white
    "#000000"
    "#ffffff"
    ))

(provide 'contrast-color)
;;; contrast-color.el ends here
