#lang racket/base

;; Noise RPC surface.
;;
;; Every operation the Swift frontend can call is a `define-rpc`. define-rpc
;; has fixed arity (no optional args) — use (Optional T) and pass nil for
;; "absent". The bodies implement your business logic.
;;
;; This example keeps an in-memory counter. Replace with your real logic
;; (e.g. open a database, talk to the filesystem, call a web API, ...).

(require noise/backend
         noise/serde
         racket/list
         "types.rkt")

(provide reset-state!)  ; useful from tests

;; --- example state ------------------------------------------------------
;; A toy in-memory store so the template does something visible out of the
;; box. Real apps would back this with SQLite / files instead.
(define counters (make-hash))
(define next-id 1)

(define (reset-state!)
  (set! counters (make-hash))
  (set! next-id 1))

;; --- RPCs ---------------------------------------------------------------

;; Create a counter, returns it.
(define-rpc (create-counter [labeled label : String] : Counter)
  (define id next-id)
  (set! next-id (add1 next-id))
  (define c (make-Counter #:id id #:label label #:value 0))
  (hash-set! counters id c)
  c)

;; Get one counter by id, or nil.
(define-rpc (get-counter [for-id id : UVarint] : (Optional Counter))
  (hash-ref counters id #f))

;; List all counters.
(define-rpc (get-all-counters : (Listof Counter))
  (sort (hash-values counters) < #:key Counter-id))

;; Increment a counter, returns the updated value.
(define-rpc (increment-counter [for-id id : UVarint] : (Optional Counter))
  (cond
    [(hash-has-key? counters id)
     (define c (hash-ref counters id))
     (define updated (make-Counter #:id (Counter-id c)
                                   #:label (Counter-label c)
                                   #:value (add1 (Counter-value c))))
     (hash-set! counters id updated)
     updated]
    [else #f]))

;; Delete a counter.
(define-rpc (delete-counter [for-id id : UVarint] : Bool)
  (hash-has-key? counters (hash-remove! counters id)))
