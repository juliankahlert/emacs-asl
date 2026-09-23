;;; asl-mode-test.el --- Tests for asl-mode -*- lexical-binding: t; -*-

(require 'ert)
(require 'asl-mode)

(defconst asl-test-fixtures-directory
  (expand-file-name "../examples/upstream" (file-name-directory load-file-name)))

(defun asl-test-face-at (source needle &optional offset)
  "Return the face at NEEDLE plus OFFSET in SOURCE."
  (with-temp-buffer
    (insert source)
    (asl-mode)
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward needle)
    (get-text-property (+ (match-beginning 0) (or offset 0)) 'face)))

(ert-deftest asl-mode-file-associations ()
  (dolist (name '("foo.asl" "foo.dsl" "foo.asi"))
    (should (eq (assoc-default name auto-mode-alist #'string-match) 'asl-mode))))

(ert-deftest asl-mode-comments-and-strings ()
  (with-temp-buffer
    (insert "// Device (FAKE)\n/* Method (NOPE) */\nName (_HID, \"Device \\\"quoted\\\"\")\n")
    (asl-mode)
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "FAKE")
    (should (nth 4 (syntax-ppss)))
    (search-forward "NOPE")
    (should (nth 4 (syntax-ppss)))
    (search-forward "quoted")
    (should (nth 3 (syntax-ppss)))
    (goto-char (point-min))
    (search-forward "Device")
    (should-not (eq (get-text-property (match-beginning 0) 'face) 'font-lock-keyword-face))))

(ert-deftest asl-mode-highlights-language-forms ()
  (let ((source "DefinitionBlock (\"\", \"SSDT\", 2, \"OEM\", \"TABLE\", 1) {\n  Device (DEV0) {\n    Name (_HID, \"PNP0C09\")\n    Method (_STA, 0, Serialized) { Return (0x0F) }\n  }\n}\n"))
    (should (eq (asl-test-face-at source "DefinitionBlock") 'font-lock-keyword-face))
    (should (eq (asl-test-face-at source "Device") 'font-lock-keyword-face))
    (should (eq (asl-test-face-at source "DEV0") 'font-lock-type-face))
    (should (eq (asl-test-face-at source "_STA") 'font-lock-function-name-face))
    (should (eq (asl-test-face-at source "Return") 'font-lock-builtin-face))
    (should (eq (asl-test-face-at source "0x0F") 'font-lock-constant-face))
    (should (eq (asl-test-face-at source "Serialized") 'font-lock-constant-face))))

(ert-deftest asl-mode-highlights-preprocessor-and-namespace ()
  (let ((source "#include <Acpi.h>\n#define GPIO 0x10\nScope (\\_SB_.PCI0) { Name (_HID, Zero) }\n"))
    (should (eq (asl-test-face-at source "#include") 'font-lock-preprocessor-face))
    (should (eq (asl-test-face-at source "_HID") 'font-lock-variable-name-face))
    (should (eq (asl-test-face-at source "Zero") 'font-lock-constant-face))))

(ert-deftest asl-mode-is-case-insensitive-and-skips-comment-keywords ()
  (let ((source "device (dev0) { method (_sta) { return (one) } } // Return\n"))
    (should (eq (asl-test-face-at source "device") 'font-lock-keyword-face))
    (should (eq (asl-test-face-at source "dev0") 'font-lock-type-face))
    (should (eq (asl-test-face-at source "return") 'font-lock-builtin-face))
    (with-temp-buffer
      (insert source)
      (asl-mode)
      (font-lock-ensure)
      (goto-char (point-min))
      (search-forward "// Return")
      (should (eq (get-text-property (+ (match-beginning 0) 3) 'face)
                  'font-lock-comment-face)))))

(ert-deftest asl-mode-opens-real-fixtures ()
  (let ((root asl-test-fixtures-directory))
    (dolist (name '("SgiSsdt.asl" "RPiDsdt.asl" "RPiSsdtThermal.asl"))
      (with-temp-buffer
        (insert-file-contents (expand-file-name name root))
        (asl-mode)
        (font-lock-ensure)
        (goto-char (point-min))
        (should (search-forward "DefinitionBlock" nil t))
        (should (eq (get-text-property (match-beginning 0) 'face)
                    'font-lock-keyword-face))))))

(provide 'asl-mode-test)
;;; asl-mode-test.el ends here
