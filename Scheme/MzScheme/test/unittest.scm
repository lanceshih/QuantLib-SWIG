; Copyright (C) 2002, 2003 RiskMap srl
;
; This file is part of QuantLib, a free-software/open-source library
; for financial quantitative analysts and developers - http://quantlib.org/
;
; QuantLib is free software developed by the QuantLib Group; you can
; redistribute it and/or modify it under the terms of the QuantLib License;
; either version 1.0, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; QuantLib License for more details.
;
; You should have received a copy of the QuantLib License along with this
; program; if not, please email ferdinando@ametrano.net
;
; The QuantLib License is also available at http://quantlib.org/license.html
; The members of the QuantLib Group are listed in the QuantLib License
;
; $Id$

(define-syntax assert
  (syntax-rules ()
    ((assert check msg1 msg2 ...)
     (if (not check)
         (error (string-append 
                 (format "~a" msg1)
                 (format "~a" msg2) ...))))))
          
; handy in formatting error messages
(define cr (format "~n"))

; a few specialized assertions
(define-syntax assert-zero
  (syntax-rules ()
    ((assert-zero x tolerance msg1 msg2 ...)
     (assert (<= (abs x) tolerance) msg1 msg2 ...))))
(define-syntax assert-equal
  (syntax-rules ()
    ((assert-equal lhs rhs tolerance msg1 msg2 ...)
     (assert-zero (- lhs rhs) tolerance msg1 msg2 ...))))
(define-syntax check-expected
  (syntax-rules ()
    ((check-expected calculated expected tolerance msg1 msg2 ...)
     (assert-equal calculated expected tolerance
                   msg1 msg2 ... cr
                   "    calculated: " calculated cr
                   "    expected:   " expected cr))))

; the test suite implementation
(define (make-suite)
  (let ((test-list '()))
	(lambda (command . args)
	  (cond
	   ; add a test to the suite
	   ((eqv? command 'add)
		(set! test-list (append test-list
								(list (cons (car args) (cadr args))))))
	   ; run the test suite
	   ((eqv? command 'run)
		(let* ((error-list '())
               (elapsed-time #f)
               (add-error
                (lambda (test-msg error-msg)
                  (set! error-list
                        (append error-list
                                (list (cons test-msg error-msg))))))
               (run-single-test
                (lambda (test)
                  (let* ((test-proc (car test))
                         (test-msg (cdr test))
                         (handle-string
                          (lambda (str)
                            (display "failed ") (newline) (flush-output)
                            (add-error test-msg str)))
                         (handle-exn
                          (lambda (e)
                            (display "failed ") (newline) (flush-output)
                            (add-error test-msg (exn-message e)))))
                    (with-handlers ((string? handle-string)
                                    (exn? handle-exn))
                      (display test-msg) (display "... ") (flush-output)
                      (test-proc)
                      (display "ok ") (newline) (flush-output)))))
               (run-all-tests
                (lambda () (for-each run-single-test test-list))))
		  (let-values (((a b c d)
						(time-apply run-all-tests '())))
					  (set! elapsed-time c))
		  (display (length test-list)) (display " test(s) run in ")
		  (display (/ elapsed-time 1.0e+3)) (display " s.") (newline)
		  (cond ((null? error-list) (display "All tests passed.") (newline))
				(else
				 (display (length error-list))
                 (display " failure(s).")
                 (newline)
				 (for-each
				  (lambda (err)
					(let ((test-msg (car err))
						  (error-msg (cdr err)))
					  (newline)
					  (display test-msg) (display ":") (newline)
					  (display error-msg)))
				  error-list)
				 (newline)))))))))

(define (suite-add-test suite test-proc test-msg)
  (suite 'add test-proc test-msg))
(define (suite-run suite)
  (suite 'run))