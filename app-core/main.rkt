#lang racket/base

;; Backend entry point.
;;
;; Boots the Noise RPC server. Requiring "rpc.rkt" for effect is what
;; registers every define-rpc with the Noise sequencer; the codegen tool
;; reads *this* module to generate Backend.swift, so the RPC surface must be
;; transitively required here.

(require noise/backend
         noise/serde
         "rpc.rkt")

(provide main)

(define (main in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (let/cc trap
    (parameterize ([exit-handler
                    (lambda (err-or-code)
                      (when (exn:fail? err-or-code)
                        ((error-display-handler)
                         (format "trap: ~a" (exn-message err-or-code))
                         err-or-code))
                      (trap))])
      (define stop (serve in-fd out-fd))
      (with-handlers ([exn:break? void])
        (sync never-evt))
      (stop))))
