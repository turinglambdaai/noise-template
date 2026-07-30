#lang info

;; Racket package metadata for the backend.
;; `collection` becomes the require prefix; deps must include noise-serde-lib.

(define collection "app")
(define version "0.1.0")
(define license 'MIT)

(define deps
  '("base"
    "threading-lib"
    ["noise-serde-lib" #:version "0.10"]))

(define build-deps
  '("rackunit-lib"))
