;;; current-emacs-ambiguous-width.el --- calculate character widths for ambiguous width characters.
;;; Commentary:
;;; requires: my-utf-8-eaw-fullwidth.el
;;; requires: init.el
;;; Requires: cl
;;; Code:
(require 'cl)
(if (not (or (member "~/.emacs.d" load-path)
             (member (expand-file-name "~/.emacs.d") load-path)))
    (setq load-path (append (list "~/.emacs.d") load-path)))
(if (not (or (member "~/.emacs.d/site-lisp" load-path)
             (member (expand-file-name "~/.emacs.d/site-lisp") load-path)))
    (setq load-path (append (list "~/.emacs.d/site-lisp") load-path)))
(load "my-utf-8-eaw-fullwidth")

(defun my-print-char-width (start-value end-value)
  "START-VALUEからEND-VALUEまでのコードポイント値に対するchar-widthをバッファ*char-width*に書き込みます。"
  (with-current-buffer (get-buffer-create "*char-width*")
    (insert (format "Range: 0x%04X-0x%04X\n" start-value end-value))
                    (let ((current start-value) (width-total 0.0) (count 0.0))
                      (while (<= current end-value)
                        (insert (format "0x%04X %d\n" current (char-width current)))
                        (setq width-total (+ width-total (char-width current)))
                        (incf count)
                        (incf current)))))


;;minttyのソースsrc/newlib/libc/string/wcwidth.cにある
;;ambiguous[]の{..., ...},という配列の中身をコピーし、
;;ambiguous_buffer.txtとして保存してください。"
(defun my-print-char-widths (filename)
  "実行ディレクトリのambiguous_buffer.txtを読み込み各ユニコード文字のコードポイントからchar-widthの値を計算します。
計算結果はFILENAMEに保存されます。"
  (if (bufferp (get-buffer "*char-width*"))
      (kill-buffer "*char-width*"))
  (if (bufferp (get-buffer "*ambiguous*"))
      (kill-buffer "*ambiguous*"))
  (with-current-buffer (get-buffer-create "*ambiguous*")
    (insert-file-contents-literally "ambiguous_buffer.txt")
    (goto-char 0)
    (let ((range nil)
          (start-hex-string nil)
          (end-hex-string nil)
          (start-prefix nil))
      (while (re-search-forward "{ 0x[0-9A-F]+, 0x[0-9A-F]+ }" nil t)
        (setq range (buffer-substring (match-beginning 0) (match-end 0)))
        (string-match "0x[0-9A-F]+" range)
        (setq start-hex-string (substring range (match-beginning 0) (match-end 0)))
        (setq start-prefix (match-end 0))
        (string-match "0x[0-9A-F]+" range start-prefix)
        (setq end-hex-string (substring range (match-beginning 0) (match-end 0)))
        (let ((start-number (string-to-number (replace-regexp-in-string "^0x" "" start-hex-string) 16))
              (end-number (string-to-number (replace-regexp-in-string "^0x" "" end-hex-string) 16)))
          (my-print-char-width start-number end-number)))))
  (with-current-buffer (get-buffer "*char-width*")
    (write-region (point-min) (point-max) filename))
  (message "See: %s." filename))

(my-print-char-widths "output/char-width_emacs-default.txt")
(load "init")
(my-print-char-widths "output/char-width_emacs-after-init-loaded.txt")

;;; current-emacs-ambiguous-width.el ends here
