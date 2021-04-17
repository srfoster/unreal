#lang at-exp racket/base

;Unzip Build.7z before running

;TODO: Tests are not passing (big payload bug)

;TODO: Pass back better errors to racket

;TODO: Use this in stream code?
;TODO: Replace in codespells
;TODO: What's the next documentation video about?
;  What would some cool visuals be?
;  Cool coding concepts? Rosette?  Mana costs?  FP?

;For docs: Sending function definitions over...
;  Abstractions.  What you can do with an unreal-value.
;  TODO: Make 



(require unreal
         rackunit)

(bootstrap-unreal-js  
 "Build\\WindowsNoEditor\\UnrealJSStarter\\Content\\Scripts"
 ;"S:\\CodeSpellsWorkspace\\Projects\\cabin-world\\Build\\WindowsNoEditor\\LogCabinWorld\\Content\\Scripts"
)

(start-unreal 
 "Build\\WindowsNoEditor\\CodeSpellsDemoWorld.exe"
 ;"S:\\CodeSpellsWorkspace\\Projects\\cabin-world\\Build\\WindowsNoEditor\\CodeSpellsDemoWorld.exe"
 )

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


(define (big-one n)
  (if (= n 0)
      @unreal-value{return "Base"}
      @unreal-value{return [[@(big-one (sub1 n))],[@(big-one (sub1 n))]]}))

(check-pred
 (compose not void?)
 (unreal-eval-js
  (big-one 10))
 "Even big JS payloads should work"
 )


(define cube
  (unreal-eval-js
   @unreal-value{
     const uclass = require('uclass')().bind(this,global);
  class MySMA extends StaticMeshActor {
   ctor() {
    this.StaticMeshComponent.SetStaticMesh(StaticMesh.Load('/Engine/BasicShapes/Cube.Cube'))
   }
  }      
  let MySMA_C = uclass(MySMA);
  return new MySMA_C(GWorld);
   }))

(check-pred
 hash?
 cube
 "Things can spawn, and data returned as hash"
 )


(define nearby-actors
  (unreal-eval-js
   @unreal-value{
 return KismetSystemLibrary.SphereOverlapActors(GWorld, {}, 1000).OutActors
 }))

(define middle-cube
  (findf
   (lambda (a)
     (regexp-match #rx"MiddleCube"
                   (hash-ref a 'RootComponent)))
   nearby-actors))

(check-pred
 hash?
 
 middle-cube
 
 "The world can be queried, data returned as arrays, hashes, etc"
 )

(check-pred
 unreal-value?
 
 (->unreal-value middle-cube)
 
 "Racket values can be converted back into unreal-values"
 )


(check-equal?
 (hash-ref middle-cube 'RootComponent)
 
 (hash-ref (unreal-eval-js
            (->unreal-value
             middle-cube))
           'RootComponent)
 
 "Racket values converted with ->unreal-value can be evaled back to the same racket value."
 )
