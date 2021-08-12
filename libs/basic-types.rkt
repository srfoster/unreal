#lang at-exp racket/base

(provide vec
         rot
         x y z
         roll pitch yaw
         +vec
         *vec
         vec?
         distance)

(define (vec? x)
  (and (hash? x)
       (hash-has-key? x 'X)
       (hash-has-key? x 'Y)
       (hash-has-key? x 'Z)))

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

(define (distance a b)
  (local-require racket/math) 
  (define x1 (hash-ref a 'X))
  (define y1 (hash-ref a 'Y))
  (define z1 (hash-ref a 'Z))
  (define x2 (hash-ref b 'X))
  (define y2 (hash-ref b 'Y))
  (define z2 (hash-ref b 'Z))
  (sqrt (+ (sqr (- x1 x2))
           (sqr (- y1 y2))
           (sqr (- z1 z2)))))