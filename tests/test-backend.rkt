#lang racket/base

;; Minimal backend test for the template's example counter logic.
;;
;; This checks the shared record's constructor/accessors and the RPC
;; business logic (without the wire format, which is exercised end-to-end by
;; the generated Swift client). Replace with tests for your own logic.

(require rackunit
         rackunit/text-ui
         "../app-core/types.rkt"
         "../app-core/rpc.rkt")

(define backend-tests
  (test-suite
   "backend"

   (test-case "Counter record"
     (define c (make-Counter #:id 1 #:label "clicks" #:value 0))
     (check-true (Counter? c))
     (check-equal? (Counter-id c) 1)
     (check-equal? (Counter-label c) "clicks")
     (check-equal? (Counter-value c) 0))

   ;; Exercise the RPC handler bodies directly (they're ordinary procedures).
   (test-case "create + increment + get + list + delete"
     (reset-state!)
     (define c1 (create-counter "clicks"))
     (check-equal? (Counter-value c1) 0)
     (define c2 (increment-counter (Counter-id c1)))
     (check-equal? (Counter-value c2) 1)
     (define c3 (increment-counter (Counter-id c1)))
     (check-equal? (Counter-value c3) 2)
     (check-equal? (Counter-value (get-counter (Counter-id c1))) 2)
     (check-equal? (length (get-all-counters)) 1)
     (check-true (delete-counter (Counter-id c1)))
     (check-false (get-counter (Counter-id c1))))))

(run-tests backend-tests)
