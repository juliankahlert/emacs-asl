;;; asl-mode.el --- ACPI Source Language editing -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Julian Kahlert
;; Author: Julian Kahlert
;; Keywords: languages, hardware
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.1.0
;; SPDX-License-Identifier: MIT

;;; Commentary:
;; A major mode for ACPI Source Language (ASL), including the .dsl output of
;; iASL and .asi include files.  It provides fontification, structural
;; indentation, C-style comments, and navigation for common ASL declarations.

;;; Code:

(defgroup asl-mode nil
  "Editing ACPI Source Language (ASL) files."
  :group 'languages)

(defcustom asl-mode-indent-offset 4
  "Number of columns to indent nested ASL forms."
  :type 'integer
  :safe #'integerp
  :group 'asl-mode)

(defcustom asl-mode-preprocessor-continuation-offset 2
  "Number of columns to indent continued preprocessor lines."
  :type 'integer
  :safe #'integerp
  :group 'asl-mode)

(defvar asl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "TAB") #'indent-for-tab-command)
    map)
  "Keymap for `asl-mode'.")

(defvar asl-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?{ "(}" table)
    (modify-syntax-entry ?} "){" table)
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\\ "\\" table)
    table)
  "Syntax table for `asl-mode'.")

(defconst asl-mode--declarations
  '("DefinitionBlock" "Scope" "Device" "Processor" "ThermalZone"
    "PowerResource" "Method" "Name" "Alias" "External"
    "OperationRegion" "Field" "IndexField" "BankField" "DataTableRegion"
    "Mutex" "Event" "CreateBitField" "CreateByteField"
    "CreateWordField" "CreateDWordField" "CreateQWordField"
    "CreateField" "Function" "Include")
  "ASL declarations and namespace construction forms.")

(defconst asl-mode--operators
  '("If" "Else" "ElseIf" "While" "Switch" "Case" "Default"
    "Break" "Continue" "Return" "Store" "CopyObject" "Notify"
    "Acquire" "Release" "Wait" "Signal" "Reset" "Sleep" "Stall"
    "Add" "Subtract" "Multiply" "Divide" "Mod" "Increment"
    "Decrement" "And" "Or" "Xor" "Not" "NAnd" "NOr"
    "ShiftLeft" "ShiftRight" "LAnd" "LOr" "LNot" "LEqual"
    "LGreater" "LLess" "LGreaterEqual" "LLessEqual" "LNotEqual"
    "ToInteger" "ToString" "ToBuffer" "ToHexString"
    "ToDecimalString" "Concatenate" "ConcatResTemplate"
    "Index" "DerefOf" "RefOf" "SizeOf" "ObjectType"
    "EISAID" "Unicode" "Load" "LoadTable" "Unload"
    "Buffer" "Package" "VarPackage" "ResourceTemplate"
    "Debug" "Fatal" "Timer")
  "Common ASL control statements, operators, and constructors.")

(defconst asl-mode--resources
  '("WordBusNumber" "DWordMemory" "QWordMemory" "Memory32Fixed"
    "DWordIO" "QWordIO" "IO" "FixedIO" "Interrupt" "IRQ"
    "IRQNoFlags" "DMA" "I2cSerialBus" "SpiSerialBus"
    "UartSerialBus" "GpioInt" "GpioIo" "EndTag")
  "Common ACPI resource descriptor constructors.")

(defconst asl-mode--constants
  '("Zero" "One" "Ones" "True" "False" "Null"
    "Serialized" "NotSerialized" "SystemMemory" "SystemIO"
    "PCI_Config" "EmbeddedControl" "SMBus" "SystemCMOS"
    "AnyAcc" "ByteAcc" "WordAcc" "DWordAcc" "QWordAcc"
    "BufferAcc" "NoLock" "Lock" "Preserve" "WriteAsOnes"
    "WriteAsZeros" "DeviceObj" "MethodObj" "IntObj" "StrObj"
    "BuffObj" "PkgObj" "FieldUnitObj" "UnknownObj")
  "Common ASL named constants and flags.")

(defconst asl-mode-font-lock-keywords
  `(("^[ \t]*\\(#[ \t]*[[:alpha:]_]+\\)" 1 font-lock-preprocessor-face)
    (,(regexp-opt asl-mode--declarations 'symbols) . font-lock-keyword-face)
    (,(regexp-opt asl-mode--operators 'symbols) . font-lock-builtin-face)
    (,(regexp-opt asl-mode--resources 'symbols) . font-lock-type-face)
    (,(regexp-opt asl-mode--constants 'symbols) . font-lock-constant-face)
    ("\\_<0[xX][[:xdigit:]]+\\_>\\|\\_<[0-9]+\\_>" . font-lock-constant-face)
    ("\\_<_[[:alnum:]_]+\\_>" . font-lock-variable-name-face)
    ("\\_<\\(?:Device\\|Processor\\|ThermalZone\\|PowerResource\\)\\_>[ \t\n]*([ \t\n]*\\([[:alnum:]_]+\\)" 1 font-lock-type-face)
    ("\\_<Method\\_>[ \t\n]*([ \t\n]*\\([[:alnum:]_]+\\)" 1 font-lock-function-name-face t))
  "Font-lock rules for `asl-mode'.")

(defconst asl-mode--imenu-generic-expression
  '(("Methods" "^[ \t]*Method[ \t]*(\\([[:alnum:]_]+\\)" 1)
    ("Devices" "^[ \t]*Device[ \t]*(\\([[:alnum:]_]+\\)" 1)
    ("Scopes" "^[ \t]*Scope[ \t]*(\\([[:alnum:]_]+\\)" 1))
  "Imenu expressions for ASL methods, devices, and scopes.")

(defun asl-mode--opener-of-kind (stack character)
  "Return the innermost position in STACK opened by CHARACTER."
  (let ((opener nil))
    (dolist (position stack)
      (when (and (eq (char-after position) character)
                 (or (not opener) (> position opener)))
        (setq opener position)))
    opener))

(defun asl-mode--opener-indentation (position)
  "Return the indentation of the line containing POSITION."
  (save-excursion
    (goto-char position)
    (current-indentation)))

(defun asl-mode--continuation-indentation (position)
  "Return the indentation for a continued argument list opened at POSITION."
  (save-excursion
    (goto-char (1+ position))
    (skip-chars-forward " \t")
    (if (and (not (eolp)) (not (eq (char-after) ?\))))
        (current-column)
      (+ (asl-mode--opener-indentation position) asl-mode-indent-offset))))

(defun asl-mode--preprocessor-continuation-indentation ()
  "Return indentation for a continued preprocessor line, if applicable."
  (save-excursion
    (beginning-of-line)
    (when (> (point) (point-min))
      (forward-line -1)
      (when (looking-at ".*\\\\[ \t]*$")
        (let ((searching t)
              indentation)
          (while searching
            (cond
             ((looking-at "^[ \t]*#")
              (setq indentation
                    (+ (current-indentation)
                       asl-mode-preprocessor-continuation-offset)
                    searching nil))
             ((= (line-beginning-position) (point-min))
              (setq searching nil))
             (t
              (forward-line -1)
              (unless (looking-at ".*\\\\[ \t]*$")
                (setq searching nil)))))
          indentation)))))

(defun asl-mode--calculate-indentation ()
  "Calculate indentation for the current ASL line."
  (save-excursion
    (back-to-indentation)
    (let* ((line-position (point))
           (state (syntax-ppss line-position))
           (stack (nth 9 state))
           (character (char-after line-position))
           (brace (asl-mode--opener-of-kind stack ?{))
           (innermost (nth 1 state))
           (paren (and innermost
                       (memq (char-after innermost) '(?\( ?\[))
                       innermost))
           (preprocessor-indent
            (asl-mode--preprocessor-continuation-indentation)))
      (cond
       ((and (memq character '(?\} ?\) ?\])))
        (if (nth 1 state)
            (asl-mode--opener-indentation (nth 1 state))
          0))
       ((and paren (or (not brace) (> paren brace)))
        (asl-mode--continuation-indentation paren))
       (preprocessor-indent preprocessor-indent)
       (brace
        (+ (asl-mode--opener-indentation brace) asl-mode-indent-offset))
       (t 0)))))

(defun asl-mode-indent-line ()
  "Indent the current line as an ASL source line."
  (interactive)
  (let ((indent (max 0 (asl-mode--calculate-indentation)))
        (offset (- (current-column) (current-indentation))))
    (indent-line-to indent)
    (when (> offset 0)
      (move-to-column (+ indent offset)))))

;;;###autoload
(define-derived-mode asl-mode prog-mode "ASL"
  "Major mode for ACPI Source Language files."
  :syntax-table asl-mode-syntax-table
  (set-keymap-parent asl-mode-map prog-mode-map)
  (setq-local font-lock-defaults '(asl-mode-font-lock-keywords nil t))
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "//+\\s-*\\|/\\*+\\s-*")
  (setq-local case-fold-search t)
  (setq-local indent-line-function #'asl-mode-indent-line)
  (setq-local imenu-generic-expression asl-mode--imenu-generic-expression)
  (setq-local electric-indent-chars
              (cons ?} (cons ?{ electric-indent-chars))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(asl\\|dsl\\|asi\\)\\'" . asl-mode))

(provide 'asl-mode)
;;; asl-mode.el ends here
