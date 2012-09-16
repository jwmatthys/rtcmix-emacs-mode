;;; -*- coding: utf-8 -*-
;;;rtcmix-mode.el --- RTcmix major mode,
;;;based on
;;;chuck-mode.el --- ChucK major mode

;; Copyright (C) 2004 Mikael Johansson

;; Author:  2012 Joel Matthys
;;          2009 Kao Cardoso Félix
;;          2004 Mikael Johansson
;; Maintainer: kcfelix@gmail.com
;; Keywords: tools, processes, languages

;; Released under the MIT license.

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; This is a mode for editing RTcmix language files and running them.

;; Information about the ChucK language can be found on
;; http://chuck.cs.princeton.edu/

;; INSTALLATION AND USE :

;; To install, put this file on your load-path and the add a line with?
;; (require 'rtcmix-mode)

;; To start using it just edit a .sco file.  You can then press C-c C-c
;; (rtcmix-add-code) to send the buffer content to RTcmix.

;;; Code:

(require 'custom)

;;; Customizable variables

(defgroup rtcmix nil
  "Support for the RTcmix programming language, <http://www.rtcmix.org/>"
  :group 'languages
  :prefix "rtcmix-")

(defcustom rtcmix-exec "/home/jwmatthys/Software/RTcmix/bin/CMIX"
  "*Command used to start the Rtcmix VM.
The default will work if `rtcmix' is on your path. If you don't
want or can't change you `PATH' env variable change this to point
to the full path of `rtcmix' (i.e `c:\\rtcmix\\bin\\rtcmix.exe')"
  :type 'string
  :group 'rtcmix)

(defcustom rtcmix-auto-save-buffer t
  "If a buffer should be saved before sent to the Rtcmix VM."
  :type 'boolean
  :group 'rtcmix)

;; mode hook for user defined actions
(defvar rtcmix-mode-hook nil)

(defun rtcmix-cmd (cmd &optional arg)
  "Sends a command to rtcmix"
  (shell-command (concat rtcmix-exec
                         " " cmd  " "
                         (or arg "")
			" &")))

;; **************************************************
;; Rtcmix inferior process handling
;; **************************************************

(defvar rtcmix-save-error
  "You need to save the buffer before sending it.")

(defun rtcmix-read-buffer ()
  (if (and (buffer-modified-p) (not rtcmix-auto-save-buffer))
      (error rtcmix-save-error)
    (let ((buffer (read-buffer "Buffer to send: "
                               (buffer-name (current-buffer)))))
      (with-current-buffer buffer
        (save-buffer)
        (current-buffer)))))

(defun rtcmix-add-code (buffer)
  "Add a buffer as a shred to the Rtcmix VM"
  (interactive (list (rtcmix-read-buffer)))
  (with-current-buffer buffer
    (let ((rtcmix-file (file-name-nondirectory buffer-file-name)))
      (rtcmix-cmd "< " rtcmix-file))))

;; **************************************************
;; Rtcmix editing enhancements
;; **************************************************

(defun rtcmix-electric-close-block (n)
  "Automatically indent after typing a }"
  (interactive "p")
  (self-insert-command n)
  (indent-according-to-mode)
  (forward-char))

;; **************************************************
;; Mode configurations
;; **************************************************

;; keymap for Rtcmix mode
(defvar rtcmix-mode-map
  (let ((rtcmix-mode-map (make-keymap)))
    ;; (define-key rtcmix-mode-map (kbd "<DEL>") 'rtcmix-delete-backward-char)
    (define-key rtcmix-mode-map (kbd "}") 'rtcmix-electric-close-block)
    (define-key rtcmix-mode-map (kbd "<RET>") 'newline-and-indent)

    (define-key rtcmix-mode-map [menu-bar rtcmix]
      (cons "Rtcmix" (make-sparse-keymap "Rtcmix")))

    (define-key rtcmix-mode-map (kbd "C-c C-c") 'rtcmix-add-code)
    (define-key rtcmix-mode-map [menu-bar rtcmix rtcmix-add-code]
      '("Sending buffer to RTcmix" . rtcmix-add-code))

    rtcmix-mode-map)
  "Keymap for Rtcmix major mode")

;; Filename binding
(add-to-list 'auto-mode-alist '("\\.sco\\'" . rtcmix-mode))

;; Come helper functions for creating font-lock entries.
(defun keyword-regexp (&rest word-list)
  (concat
   "\\<\\("
   (mapconcat 'identity word-list "\\|")
   "\\)\\>"))
(defun symbol-regexp (&rest symbol-list)
  (concat
   "\\_<\\("
   (mapconcat 'identity symbol-list "\\|")
   "\\)\\_>"))
(defun rtcmix-library-regexp (namespace &rest symbol-list)
  (concat
   "\\<" namespace "\\.\\("
   (mapconcat 'identity symbol-list "\\|")
   "\\)\\>"))

;; Syntax highlighting
(defconst rtcmix-font-lock-keywords-1
  (list
   (cons (keyword-regexp
          ;; Primitive types
          ;;"int" "float" "time" "dur" "void" "same"
          ;; Reference types
          ;;"Object" "array" "Event" "UGen" "string"
          ;; Complex types
          ;;"polar" "complex"
          ;; standard Rtcmix unit generators:
          "AM" "AMINST" "BUTTER" "CLAR" "COMBIT"
          "COMPLIMIT" "CONVOLVE" "DCBLOCK" "DECIMATE"
          "DEL1" "DELAY" "DISTORT" "DMOVE" "DUMP"
          "ELL" "EQ" "FIR" "FILTERBANK" "FILTSWEEP"
          "FMINST" "FLANGE" "FOLLOWER" "FOLLOWBUTTER"
          "FOLLOWGATE" "FREEVERB" "GRANSYNTH" "GRANULATE"
          "GVERB" "HALFWAVE" "HOLO" "IIR" "setup"
          "INPUTSIG" "IINOISE" "BUZZ" "PULSE" "JCHOR"
          "JDELAY" "JFIR" "JGRAN" "LPCPLAY" "LPCIN"
          "MAXBANG" "MAXMESSAGE" "MBANDEDWG" "MBLOWBOTL"
          "MBLOWHOLE" "MBOWED" "MBRASS" "MCLAR" "METAFLUTE"
          "SFLUTE" "VSFLUTE" "BSFLUTE" "LSFLUTE" "MIX"
          "MMESH2D" "MMODALBAR" "MMOVE" "MPLACE" "MOCKBEND"
          "MOOGVCF" "MOVE" "MROOM" "MSAXOFONY" "MSHAKERS"
          "MSITAR" "MULTICOMB" "MULTEQ" "MULTIWAVE"
          "NOISE" "NPAN" "PAN" "PANECHO" "PFSCHED" "PLACE"
          "PVOC" "QPAN" "REV" "REVERBIT" "REVMIX" "ROOM"
          "SCRUB" "SCULPT" "SGRANR" "SHAPE" "SPECTACLE"
          "SPECTACLE2" "SPECTEQ" "SPECTEQ2" "SPLITTER"
          "SROOM" "STEREO" "STGRANR" "STRUM" "START"
          "BEND" "FRET" "START1" "BEND1" "FRET1"
          "VSTART1" "VFRET1" "STRUM2" "STRUMFB" "SYNC"
          "TRANS" "TRANS3" "TRANSBEND" "TVSPECTACLE"
          "VOCODE2" "VOCODE3" "VOCODESYNTH" "VWAVE"
          "WAVETABLE" "WAVESHAPE" "WAVY" "WIGGLE")
         'font-lock-type-face)
   (cons (keyword-regexp
          ;; Control structures
          "if" "else" "while" "for" "exit" "include")
         'font-lock-keyword-face)
   (cons (keyword-regexp
          ;; Special values
          "SR" "DUR" "LEFT_PEAK" "PEAK" "RIGHT_PEAK" "CHANS"
          "abs" "add" "ampdb" "boost" "bus_config" "control_rate"
          "copytable" "cpslet" "cpsmidi" "cpsoct" "cpspch" "div"
          "dumptable" "dbamp" "f_arg" "filechans" "filedur"
          "filepeak" "filesr" "getamp" "getpch" "get_spray"
          "i_arg" "index" "irand" "len" "load" "log" "makeLFO"
          "makeconnection" "makeconverter" "makefilter"
          "makemonitor" "maketable" "makerandom" "max" "midipch"
          "min" "mod" "modtable" "mul" "n_args" "octpcs" "octlet"
          "octmidi" "octpch" "pchcps" "pchlet" "pchmidi" "pchoct"
          "pickrand" "pickwrand" "plottable" "pow" "print" "printf"
          "print_off" "print_on" "rand" "random" "reset" "round"
          "rtinput" "rtoutput" "rtsetparams" "s_arg" "samptable"
          "set_option" "spray_init" "srand" "stringify" "sub" "system"
          "tablelen" "trand" "translen" "trunc" "type" "wrap")
         'font-lock-keyword-face)

   ;; rtcmix operators and debug print
   (cons (symbol-regexp "=" "+=" "-=" "*=" "/=")
         'font-lock-operator-face))

  "Highlighting for Rtcmix mode")

(defvar rtcmix-font-lock-keywords rtcmix-font-lock-keywords-1
  "Default highlighting for Rtcmix mode")

;; Indenting for Rtcmix mode
(defun rtcmix-indent-line ()
  "Indent current line as Rtcmix code"
  (interactive)
  (beginning-of-line)
  (if (bobp)  ;; Start of buffer starts out unindented
      (indent-line-to 0)
    (let ((not-indented t)
                  cur-indent)
      (if (looking-at "[[:blank:]]*}") ; Closing a block
                  (progn
                        (save-excursion
                          (forward-line -1)
                          (setq cur-indent (- (current-indentation) default-tab-width)))
                        (if (< cur-indent 0)
                                (setq cur-indent 0)))
                (save-excursion
                  (while not-indented
                        (forward-line -1)
                        (cond ((looking-at ".*{") ; In open block
                                   (setq cur-indent (+ (current-indentation) default-tab-width))
                                   (setq not-indented nil))
                                  ((looking-at "[[:blank:]]*}") ; Closed block on blank line
                                   (setq cur-indent (current-indentation))
                                   (setq not-indented nil))
                                  ((looking-at ".*}") ; Closed block on non-blank line
                                   (setq cur-indent (- (current-indentation) default-tab-width))
                                   (setq not-indented nil))
                                  ((bobp)
                                   (setq not-indented nil))))))
      (if cur-indent
                  (indent-line-to cur-indent)
                (indent-line-to 0)))))

;; Syntax table
(defvar rtcmix-mode-syntax-table nil "Syntax table for Rtcmix mode")
(setq rtcmix-mode-syntax-table
      (let ((rtcmix-mode-syntax-table (make-syntax-table)))
        (modify-syntax-entry ?_ "_" rtcmix-mode-syntax-table)
        (modify-syntax-entry ?/ ". 12" rtcmix-mode-syntax-table)
        (modify-syntax-entry ?\n ">" rtcmix-mode-syntax-table)
        rtcmix-mode-syntax-table))

;; Entry point
(defun rtcmix-mode ()
  "Major mode for editing Rtcmix music/audio scripts"
      (interactive)
  (kill-all-local-variables)
  (set-syntax-table rtcmix-mode-syntax-table)
  (use-local-map rtcmix-mode-map)
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'font-lock-defaults)
       '(rtcmix-font-lock-keywords))
  (set (make-local-variable 'indent-line-function)
       'rtcmix-indent-line)

  (setq major-mode 'rtcmix-mode)
  (setq mode-name "RTcmix")
  (setq default-tab-width 4)
  (run-hooks 'rtcmix-mode-hook))

(provide 'rtcmix-mode)
;;; rtcmix-mode.el ends here
