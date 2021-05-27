#lang at-exp racket/base

;Move all of this to an unreal lib...

(require unreal
         unreal/libs/basic-shapes
         unreal/libs/basic-types
         unreal/libs/actors
         unreal/external-runtime/main)

;(bootstrap-and-start-unreal)

(define player-start 
  (unreal-eval-js (find-actor ".*PlayerStart.*")))


(define spawn1 
  (unreal-eval-js (exported-class->actor "PickupMini" 
                                         #:location (locate player-start))))

(spell-language-module 'unreal/external-runtime/test-lang-external) 

(add-spawn! "test1" spawn1)

(run-spell "test1"
           '(let loop ()
              (inc)
              (loop))
           '())

(sleep 1)

(require rackunit
         unreal/external-runtime/test-lang)

(check-pred 
 (lambda (x) (< 0 x))
 count
 "Count should not be 0")

(displayln "Tests complete")