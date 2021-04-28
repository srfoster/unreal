#lang at-exp racket/base

(provide with-name
         get-named-things
         clear-named-things)

(require unreal
         unreal/libs/actors)

(define (clear-named-things)
  @unreal-value{
   global.namedThings = {}
   return undefined                    
 })

(define (get-named-things)
  @unreal-value{
   return global.namedThings                    
 })

(define (with-name n [uv #f])
  (if (not uv)
      @unreal-value{
 global.namedThings = global.namedThings || {}

 var n = @(->unreal-value n)
 return global.namedThings[n]               
}
      @unreal-value{
 global.namedThings = global.namedThings || {}
 var n = @(->unreal-value n)

 var alreadyNamed = global.namedThings[n]

 if(alreadyNamed && alreadyNamed.DestroyActor){
   @(destroy-actor
     @unreal-value{return alreadyNamed})
 } 

 global.namedThings[n] = @uv        

 return global.namedThings[n] 
 }))




(module+ test
  (require rackunit
           unreal/libs/basic-shapes)
  
  (bootstrap-unreal-js  
   "..\\Build\\WindowsNoEditor\\UnrealJSStarter\\Content\\Scripts"
   )

  (start-unreal 
   "..\\Build\\WindowsNoEditor\\CodeSpellsDemoWorld.exe"
   )

  (unreal-eval-js (clear-named-things))

  (check-equal?
   (hasheq)
   (unreal-eval-js (get-named-things))
   "There should be no named things")

  (unreal-eval-js (with-name "test"
                    (->unreal-value
                     (hasheq 'X 0))))
  
  (check-equal?
   (hasheq 'X 0)
 
   (unreal-eval-js
    (with-name "test"))

   "The thing named 'test' should be what we stored")


  (check-equal?
   (void)
 
   (unreal-eval-js
    (with-name "test2"))

   "If we didn't store it, it should be void")

  (define c1
    (unreal-eval-js
     (with-name "cube"
       (cube))))
  
  (check-pred
   unreal-actor?
   (unreal-eval-js
    (with-name "cube"))
   "The thing named 'cube' should be an actor")

  (define c2
    (unreal-eval-js
     (with-name "cube"
       (cube))))

  (check-pred
   void?
   (unreal-eval-js
    (->unreal-value c1))
   "The first cube should be destroyed now")



  (check-equal?
   2
   (length
    (hash-keys
     (unreal-eval-js (get-named-things))))
   "There should be 2 named things")

  (unreal-eval-js (clear-named-things))

  )

