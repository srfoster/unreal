#lang at-exp racket/base

(provide
 ;Encapsulates a minimal chunk to be sent for evaluation in Unreal.js (soon to be Verse?)
 unreal-value
 unreal-eval-js
 unreal-server-port

 bootstrap-unreal-js
 start-unreal)



(require racket/string
         racket/list
         racket/format
         net/http-easy

         unreal/bootstrap
         unreal/start-unreal)



(struct unreal-js-fragment (content) #:prefab)


(define (string-or-fragment->string s)
  (cond [(string? s) s]
        [(symbol? s) (~a s)]
        [(number? s) (~a s)]
        [(unreal-js-fragment? s) (unreal-js-fragment-content s)]
        [(procedure? s) (string-or-fragment->string (s))]
        [else (error "You passed something that wasn't a string, js-fragment, or procedure into unreal-js")]))


(define (unreal-js . ss)
  (unreal-js-fragment
   (string-join (flatten
                 (map string-or-fragment->string
                      ss))
                "")))

(define (unreal-value . code)
  ;TODO: Static analysis / transformations on the JS code,
  ;  prevent weird variable collisions that might
  ;  happen when you nest these unreal-values inside each other.
  @unreal-js{
 (function(){
   @(apply unreal-js code);
  })()
 })


(define (unreal-eval-js . js-strings-or-fragments)
  (define js (string-join (map string-or-fragment->string js-strings-or-fragments) ""))

  (displayln "************* unreal-eval-js ******************")

  (with-handlers ([exn:fail:network:errno?
                   (lambda (e)
                     (displayln e)
                     (displayln (~a "No World server found at 127.0.0.1:" (unreal-server-port) ".  Trying again in 5 seconds..."))
                     (sleep 5)
                     
                     (unreal-eval-js js))
                   ])
    
    (define r
      (with-handlers ([exn:fail?
                       (lambda (e)
                         e)])
          (response-json
           (post (~a "127.0.0.1:" (unreal-server-port) "/js")
                 #:close? #t
                 #:data js))))

    (displayln "Sent Magic Across to word: ")
    (displayln js)

    (displayln "Response:")
    (displayln r)

    (when (hash? r)
      (hash-ref r 'value (void)))
    ))