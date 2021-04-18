#lang at-exp racket/base

(provide
 ;Encapsulates a minimal chunk to be sent for evaluation in Unreal.js (soon to be Verse?)
 unreal-value
 unreal-eval-js
 unreal-server-port
 ->unreal-value

 (rename-out [unreal-js-fragment unreal-value?])

 bootstrap-unreal-js
 start-unreal)



(require racket/string
         racket/list
         racket/format
         net/http-easy

         unreal/bootstrap
         unreal/start-unreal)

(define unreal-server-port (make-parameter 8080))

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

 ; (displayln "************* unreal-eval-js ******************")

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

  ;  (displayln "Sent Magic Across to word: ")
  ;  (displayln js)

  ;  (displayln "Response:")
  ;  (displayln r)

    (when (hash? r)
      (let ()
        (define ret (hash-ref r 'value (void)))

        ret))
    ))

(define (->unreal-value rv)
  (local-require json)

  ;(displayln "RV")
  ;(displayln rv)
  
  (define (actor? rv)
    
    (and (hash? rv)
         (hash-has-key? rv 'bAlwaysRelevant)))
  
  (cond
    [(unreal-js-fragment? rv)
     (displayln "Frag")
     rv]
    [(actor? rv)
     (begin
       ;Dubious.  Does everything have a RootComponent?
       (define rc (hash-ref rv 'RootComponent))
       #|
      Would prefer this, but not working! Why??                                                              
      let allActors = GameplayStatics.GetAllActorsOfClass(Actor).OutActors
      
      This parse/stringify trick gives me the "RootComponent" as a string that
      seems like it can be used like an id.
      Seems like there should be a more efficient way of getting this, though.
      |#
       @unreal-value{
      let allActors = KismetSystemLibrary.SphereOverlapActors(GWorld, {}, 100000).OutActors

      return allActors.filter((a)=>{return JSON.parse(JSON.stringify(a)).RootComponent == @(~s rc)})[0]
      })]
    [(list? rv)
     @unreal-value{
      return [@(string-join (map (compose unreal-js-fragment-content
                                          ->unreal-value)
                                 rv) ",")]
      }]
    [(hash? rv)
     @unreal-value{
      return {@(string-join
                (for/list ([k (hash-keys rv)]
                           [v (hash-values rv)])
                  (~a "\"" k "\"" ":" (unreal-js-fragment-content
                                       (->unreal-value v))))
                ",")}

      }]
    [(number? rv) @unreal-value{return @rv}]
    [(string? rv) @unreal-value{return @(~s rv)}]
    [(boolean? rv) @unreal-value{return @(jsexpr->string rv)} ]
    [else
     (error "Can't ->unreal-value that" rv)
     #;
     (jsexpr->string rv)]
    )

  )





