#lang racket/base

(provide inc
         count
         with-spawn
         with-args
         generator
         
         let
         quote
         #%module-begin
         #%top-interaction
         #%app
         #%datum)

(require racket/generator)
(define count 0)
(define (inc) 
  (set! count (add1 count))
  (displayln count))
(define-syntax-rule (with-args lines ...)
  (let () lines ...))
(define-syntax-rule (with-spawn lines ...)
  (let () lines ...))
