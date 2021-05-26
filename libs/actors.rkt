#lang at-exp racket

(provide destroy-actor
         find-actor
         locate
         exported-class->actor)

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

(define/contract (locate obj)
  (-> any/c unreal-value?)
  
  @unreal-value{
 var obj = @(->unreal-value obj);
 return obj.GetActorLocation();
 })