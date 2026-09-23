;;; asl-mode.el --- ACPI Source Language highlighting -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Julian Kahlert
;; Author: Julian Kahlert
;; Keywords: languages, hardware
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.1.0
;; SPDX-License-Identifier: MIT

;;; Commentary:
;; A lightweight major mode for ACPI Source Language (ASL), including the
;; .dsl output of iASL and .asi include files.  It supports C-style comments,
;; strings, preprocessor directives, and common ASL operators and names.

;;; Code:

(defvar asl-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
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
    "CreateField" "Function")
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
    ("\\_<\\(?:Device\\|Processor\\|ThermalZone\\|PowerResource\\)\\_>[ \t]*(+[ \t]*\\([[:alnum:]_]+\\)" 1 font-lock-type-face)
    ("\\_<Method\\_>[ \t]*(+[ \t]*\\([[:alnum:]_]+\\)" 1 font-lock-function-name-face t))
  "Font-lock rules for `asl-mode'.")

;;;###autoload
(define-derived-mode asl-mode prog-mode "ASL"
  "Major mode for ACPI Source Language files."
  :syntax-table asl-mode-syntax-table
  (setq-local font-lock-defaults '(asl-mode-font-lock-keywords nil t))
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "//+\\s-*")
  (setq-local indent-line-function #'indent-relative))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(asl\\|dsl\\|asi\\)\\'" . asl-mode))

(provide 'asl-mode)
;;; asl-mode.el ends here
