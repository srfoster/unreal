#lang at-exp racket/base

(require unreal)

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

 if(!global.namedThings[n]){
  global.namedThings[n] = @uv
 }

 return global.namedThings[n] 
 }))



(module+ test
  (require rackunit)
  
  (bootstrap-unreal-js  
   "..\\Build\\WindowsNoEditor\\UnrealJSStarter\\Content\\Scripts"
   )

  (start-unreal 
   "..\\Build\\WindowsNoEditor\\CodeSpellsDemoWorld.exe"
   )


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
  
  )

