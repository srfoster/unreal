#lang at-exp racket

(provide destroy-actor
         find-actor
         location
         (rename-out [location locate])
         scale
         velocity
         set-location
         set-scale
         exported-class->actor
         get-all-actors)

(require unreal
         unreal/libs/basic-types)

;Spawns by class-name, if that string is in the class assets list for your world's JS object
(define (exported-class->actor class-name
                               #:location [loc (vec 0 0 0)])
  @unreal-value{
 var Spawn = Root.ResolveClass(@(->unreal-value class-name));
 var spawn = new Spawn(GWorld, @(->unreal-value loc));
 
 return spawn;
 })

(define (find-actor name)
  @unreal-value{
 var allActors = GWorld.GetAllActorsOfClass(Actor).OutActors
 if(allActors.length == 0){
  throw("Unreal.js crapped out.")
 }
 return allActors.filter((a)=>{return a.GetDisplayName().match(new RegExp(@(->unreal-value name), "g"))})[0]
 })

(define (destroy-actor doomed)
  @unreal-value{
 var destroy = function(a){
  a.GetAttachedActors().OutActors.map(destroy)
  
  a.DestroyActor()                         
 }
                          
 var doomed = @(->unreal-value doomed)
 
 destroy(doomed);
 
 return undefined
 })

(define (scale obj [new-scale #f])
  (if new-scale
      (set-scale obj new-scale)
      @unreal-value{
        var obj = @(->unreal-value obj);
        return obj.GetActorScale3D();
      }))

(define (set-scale a s)
  @unreal-value{
 var a = @(->unreal-value a)
 var s = @(->unreal-value s)
 
 a.SetActorScale3D(s) 

 return a
 })

(define (location obj [new-loc #f])
  (if new-loc
      (set-location obj new-loc)
      @unreal-value{
        var obj = @(->unreal-value obj);
        return obj.GetActorLocation();
      }))

(define (set-location a l)
  @unreal-value{
 var a = @(->unreal-value a)
 var l = @(->unreal-value l)
 
 a.SetActorLocation(l) 

 return a
 })

(define (velocity a [new-vel #f])
  @unreal-value{
    return @(->unreal-value a).GetVelocity()
  })


(define (get-all-actors)
  @unreal-value{
    return GWorld.GetAllActorsOfClass(Actor).OutActors
 })
 
(define (camera [num 0])
  @unreal-value{
 return GWorld.GetAllActorsOfClass(CameraActor).OutActors[(->unreal-value num)]
 })
