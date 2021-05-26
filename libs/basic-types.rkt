#lang at-exp racket/base

(provide vec
         rot
         x y z
         roll pitch yaw
         +vec
         *vec)

(require unreal)

(define (vec x y z)
  (hash 'X x 'Y y 'Z z))

(define (rot x y z)
  (hash 'Roll x 'Pitch y 'Yaw z))

(define (x l)
  (hash-ref l 'X))

(define (y l)
  (hash-ref l 'Y))

(define (z l)
  (hash-ref l 'Z))

(define (roll l)
  (hash-ref l 'Roll))

(define (pitch l)
  (hash-ref l 'Pitch))

(define (yaw l)
  (hash-ref l 'Yaw))

(define (+vec l1 l2)
  (vec (+ (x l1) (x l2))
       (+ (y l1) (y l2))
       (+ (z l1) (z l2))))

(define (*vec s l1)
  (vec (* (x l1) s)
       (* (y l1) s)
       (* (z l1) s)))
