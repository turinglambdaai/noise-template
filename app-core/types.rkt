#lang racket/base

;; Shared Noise serde types.
;;
;; Declare every struct you want to marshal between Racket and Swift here
;; with `define-record` (or `define-enum`). noise-serde-codegen reads these
;; and emits matching Swift types (Readable + Writable + Sendable).

(require noise/serde)

(provide (record-out Counter))

;; A simple example record. Replace this with your own domain types.
;; Field types: String, Bool, Varint, UVarint, Float32/64, Int16/32, UInt16/32,
;; and the combinators (Listof T), (Optional T), (HashTable K V).
;;
;; NOTE: avoid naming a record `Task` — it clashes with Swift's concurrency
;; `Task` type on the generated-client side.
;;
;; Declaring `Identifiable` makes the type work directly with SwiftUI
;; List/ForEach (it requires an `id`) — the `id` field below satisfies it.
(define-record (Counter : Identifiable)
  [id    : UVarint]
  [label : String]
  [value : Varint])
