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

(define-macro assert
  (lambda (check . msg)
    `(if (not ,check)
         (error
          (apply string-append (map (lambda (token) (format #f "~A" token)) 
                                    (list ,@msg)))))))
; handy in formatting error messages
(define cr "\n")

; a few specialized assertions
(define-macro assert-zero
  (lambda (x tolerance . msg)
    `(assert (<= (abs ,x) ,tolerance) ,@msg)))
(define-macro assert-equal
  (lambda (lhs rhs tolerance . msg)
    `(assert-zero (- ,lhs ,rhs) ,tolerance ,@msg)))
(define-macro check-expected
  (lambda (calculated expected tolerance . msg)
    `(assert-equal ,calculated ,expected ,tolerance
                   ,@msg cr
                   "    calculated: " ,calculated cr
                   "    expected:   " ,expected cr)))

; the test-suite implementation
(define (make-suite)
  (let ((test-list '()))
	(lambda (command . args)
	  (cond
	   ; add a test to the suite
	   ((eqv? command 'add)
        (let ((test-case (car args))
              (test-name (cadr args)))
          (set! test-list 
                (append test-list
                        (list (cons test-case
                                    test-name))))))
	   ; run the test suite
	   ((eqv? command 'run)
		(letrec ((elapsed-time #f)
                 (error-list '())
				 (add-error
				  (lambda (test-msg error-msg)
					(set! error-list
						  (append error-list
								  (list (cons test-msg error-msg))))))
				 (run-single-test
				  (lambda (test)
					(letrec ((test-proc (car test))
							 (test-msg (cdr test))
							 (handler
							  (lambda (key . args)
								(display "failed ") (newline) 
                                (flush-all-ports)
								(add-error test-msg
                                           (apply format 
                                                  (cons #f (cdr args))))))
                             (run-test
                              (lambda ()
                                (display test-msg) (display "... ") 
                                (flush-all-ports)
                                (test-proc)
                                (display "ok ") (newline) 
                                (flush-all-ports))))
                      (catch #t run-test handler))))
				 (run-all-tests
				  (lambda () (for-each run-single-test test-list))))
          (set! elapsed-time (tms:clock (times))) ; actually the start time
          (run-all-tests)
          (set! elapsed-time (/ (- (tms:clock (times)) elapsed-time) 100.0))
          (format #t "~A test(s) run in ~A s.\n" 
                  (length test-list) elapsed-time)
		  (cond ((null? error-list) 
                 (format #t "All tests passed.\n"))
				(else
				 (format #t "~A failure(s).\n" (length error-list))
				 (for-each
				  (lambda (err)
					(let ((test-msg (car err))
						  (error-msg (cdr err)))
					  (newline)
					  (display test-msg) (display ":") (newline)
					  (display error-msg)))
				  error-list)
				 (newline)))))))))

(define (suite-add-test suite test-proc test-name)
  (suite 'add test-proc test-name))
(define (suite-run suite)
  (suite 'run))