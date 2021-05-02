#lang at-exp racket/base

;Unzip Build.7z before running


(require unreal
         rackunit
         racket/list
         racket/runtime-path)

(define-runtime-path here ".")

(bootstrap-unreal-js  
 (build-path here "Build\\WindowsNoEditor\\UnrealJSStarter2\\Content\\Scripts"))

(start-unreal 
 (build-path here "Build\\WindowsNoEditor\\UnrealJSStarter2.exe"))

(define some-js-value
  @unreal-value{
   console.log("Did it work??")

   return "Am I a value???"
 })

(check-equal?
 "Am I a value???"
 
 (unreal-eval-js some-js-value)

 "JS strings should martial to strings")

(check-equal?
 "Am I\na value???"
 
 (unreal-eval-js @unreal-value{
   return "Am I\na value???"
 })

 "JS strings with newlies should martial to strings correctly")



(check-equal?
 5
 
 (unreal-eval-js
  @unreal-value{
 console.log("Did it work??")

 return 5
 })

 "JS numbers should martial to numbers")

(check-equal?
 '(1 2 3)
  
 (unreal-eval-js
  @unreal-value{
 console.log("Did it work??")

 return [1,2,3]
 })

 "JS arrays should martial to lists")

(check-equal?
 (hasheq 'x "I am X" 'y "I am Y")
 
 (unreal-eval-js
  @unreal-value{
 console.log("Did it work??")

 return {x: "I am X", y: "I am Y"}
 })

 "JS objects should martial to hashes")


(define embedded-value
  @unreal-value{
   var x = "I am Y"
   return x
 })

(check-equal?
 (hasheq 'x "I am X" 'y "I am Y")
 
 (unreal-eval-js
  @unreal-value{
 console.log("Did it work??")

 var x = "I am X"

 return {x: x, y: @embedded-value}
 })
 
 "An unreal-value should embed in another unreal value")


(check-equal?
 "Am I a value???"
 
 (unreal-eval-js
  @unreal-value{
   return @(->unreal-value "Am I a value???")
 })

 "->unreal-value should convert racket values such that they become the appropriate js type")


(check-equal?
 777
 
 (unreal-eval-js
  @unreal-value{
   return @(->unreal-value 777)
 })

 "->unreal-value should convert racket values such that they become the appropriate js type")


(check-equal?
 (hasheq 'X 500)
 
 (unreal-eval-js
  @unreal-value{
   return @(->unreal-value (hash 'X 500))
 })

 "->unreal-value should convert racket values such that they become the appropriate js type")


(check-equal?
 '(1 2 3)
 
 (unreal-eval-js
  @unreal-value{
   return @(->unreal-value '(1 2 3))
 })

 "->unreal-value should convert racket values such that they become the appropriate js type")

(check-equal?
 '(1 2 3)
 
 (unreal-eval-js
  (->unreal-value '(1 2 3)))

 "->unreal-value should convert racket values such that they become the appropriate js type")




(define (big-one n)
  (if (= n 0)
      @unreal-value{return "Base"}
      @unreal-value{return [[@(big-one (sub1 n))],[@(big-one (sub1 n))]]}))

(check-pred
 (compose not exn:fail?)
 (unreal-eval-js
  (big-one 10))
 "Even big JS payloads should work"
 )

(displayln "Tests complete")