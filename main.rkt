#lang at-exp racket/base

(provide
 ;Encapsulates a minimal chunk to be sent for evaluation in Unreal.js (soon to be Verse?)
 unreal-value
 unreal-eval-js
 unreal-server-port
 ->unreal-value

 (rename-out [unreal-js-fragment unreal-value?])

 bootstrap-unreal-js
 start-unreal

 unreal-actor?

 unreal-debug)



(require racket/string
         racket/list
         racket/format
         net/http-easy

         unreal/bootstrap
         unreal/start-unreal
         unreal/tcp/server)

(define unreal-server-port (make-parameter 8080))

(struct unreal-js-fragment (content) #:prefab)


(define (string-or-fragment->string s)
  (cond [(unreal-js-fragment? s) (unreal-js-fragment-content s)]
        [(string? s) s]
        [else (~a s)]))


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

(define unreal-debug (make-parameter #f))

(define (unreal-eval-js #:debug [debug (unreal-debug)] . js-strings-or-fragments)

  (define js (string-join (map string-or-fragment->string js-strings-or-fragments) ""))

 ; (displayln "************* unreal-eval-js ******************")

  (define result
    (if (use-deprecated-unreal-webserver) 
        (deprecated-unreal-eval-js debug js)
        (tcp-unreal-eval-js debug js)))

  (when (unreal-error? result)
    (define message (hash-ref result 'error))
    ;Unreal(.js?) sometimes just fails for no reason, see https://github.com/ncsoft/Unreal.js/issues/300
    ;  We'll catch the special error message (defined in bootstrap.rkt) and retry.  Gross..
    (if (regexp-match #"Unreal.js crapped out" message)
        (let ()
          (displayln "Unreal.js crapped out, retrying...")
          (sleep 0.01)
          (set! result (unreal-eval-js #:debug debug js)))
        (let ()
          (displayln "Legit Unreal.js error thrown...")
          (raise-user-error message))))

  result)

(define (tcp-unreal-eval-js debug js)
  (send-to-unreal js))

(define (deprecated-unreal-eval-js debug js)
  (with-handlers ([exn:fail:network:errno?
                   (lambda (e)
                     (displayln e)
                     (displayln (~a "No World server found at 127.0.0.1:" (unreal-server-port) ".  Trying again in 5 seconds..."))
                     (sleep 5)
                     
                     (unreal-eval-js #:debug debug js))
                   ])
    
    (define r
      (with-handlers ([exn:fail?
                       (lambda (e)
                         e)])
        (response-json
         (post (~a "127.0.0.1:" (unreal-server-port) "/js")
               #:close? #t
               #:data js))))
    
    (when debug
      (displayln "Sent Magic Across to word: ")
      (displayln js)
      
      (displayln "Response:")
      (displayln r))
    
    (if (eof-object? r)
        (void)
        r)))
  

(define (unreal-actor? rv)
  (and (hash? rv)
       (hash-has-key? rv 'id)
       (hash-has-key? rv 'type)
       (string=? "actor" (hash-ref rv 'type))))

(define (unreal-error? rv)
  (and (hash? rv)
       (hash-has-key? rv 'type)
       (string=? "error" (hash-ref rv 'type))))

(define (->unreal-value rv)
  (local-require json)

  ;(displayln "RV")
  ;(displayln rv)
  
  
  (cond
    [(unreal-js-fragment? rv)
     rv]
    [(unreal-actor? rv)
     @unreal-value{
      var allActors = GWorld.GetAllActorsOfClass(Actor).OutActors;
      if(allActors.length == 0){
        throw("Unreal.js crapped out.");
      }
      return allActors.filter((a)=>{return a.GetDisplayName() == @(->unreal-value (hash-ref rv 'id))})[0];
     }]
    [(list? rv)
     @unreal-value{
      return [@(string-join (map (compose unreal-js-fragment-content
                                          ->unreal-value)
                                 rv) ",")]
      }]
    [(hash? rv)
     @unreal-value{
      return {@(string-join
                (for/list ([k (hash-keys rv)])
                  (define v (hash-ref rv k))
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
     (jsexpr->string rv)]))





