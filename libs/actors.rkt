#lang at-exp racket

(provide destroy-actor
         find-actor
         locate
         (rename-out [locate location])

         velocity
         set-location

         exported-class->actor

         get-all-actors 
         )

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

(define (locate obj)
  @unreal-value{
 var obj = @(->unreal-value obj);
 return obj.GetActorLocation();
 })


(define (velocity a)
  @unreal-value{
    return @(->unreal-value a).GetVelocity()
  })

(define (set-location a l)
  @unreal-value{
 var a = @(->unreal-value a)
 var l = @(->unreal-value l)
 
 a.SetActorLocation(l) 

 return a
 })

(define (get-all-actors)
  @unreal-value{
    return GWorld.GetAllActorsOfClass(Actor).OutActors
 })
 
(define (camera [num 0])
  @unreal-value{
 return GWorld.GetAllActorsOfClass(CameraActor).OutActors[(->unreal-value num)]
 })
