#lang at-exp racket/base

;Unzip Build.7z before running

;TODO: Demo twitch bot + unreal integration (just running
;  Would video content about this topic be interesting?  (Would be a short file...)

;TODO: Tests are not passing (big payload bug)

;TODO: Pass back better errors to racket

;TODO: Use this in stream code?
;TODO: Replace in codespells
;TODO: What's the next documentation video about?
;  What would some cool visuals be?
;  Cool coding concepts? Rosette?  Mana costs?  FP?

;For docs: Sending function definitions over...
;  Abstractions.  What you can do with an unreal-value.




(require unreal
         rackunit

         racket/list)

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


(define cube
  (unreal-eval-js
   @unreal-value{
     const uclass = require('uclass')().bind(this,global);
  class MySMA extends StaticMeshActor {
   ctor() {
    this.StaticMeshComponent.SetStaticMesh(StaticMesh.Load('/Game/HexTile_mesh'))
    this.StaticMeshComponent.SetMobility('Movable');
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
     (regexp-match #rx"MiddleHex"
                   (hash-ref a 'id)))
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
 (hash-ref middle-cube 'id)
 
 (hash-ref (unreal-eval-js
            (->unreal-value
             middle-cube))
           'id)
 
 "Racket values converted with ->unreal-value can be evaled back to the same racket value."
 )

(check-equal?
 (length (take nearby-actors 3))
 
 (length
  (unreal-eval-js
   (->unreal-value (take nearby-actors 3))))
 
 "Racket values converted with ->unreal-value can be evaled back to the same racket value."
 )


;Weird things that do work

#|

(define enable-physics
    @unreal-value{
      return (x) =>{       
      x.StaticMeshComponent.SetSimulatePhysics(true);
      x.StaticMeshComponent.SetEnableGravity(true);

      x.StaticMeshComponent.SetMobility('Movable');

      return x
      }
    })

(unreal-eval-js
 @unreal-value{
 return @(->unreal-value
          (take nearby-actors 10)).map(@enable-physics)
 })

|#


#;
(define falling-things
  (map (compose unreal-eval-js enable-physics)
       nearby-actors))
