#lang at-exp racket

(provide destroy-actor)

(require unreal)

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