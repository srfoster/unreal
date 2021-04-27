#lang at-exp racket/base

(provide enable-physics)

(require unreal)

;IDEA: keyword params for physics/gravity/mobility
(define (enable-physics actor)
  ;IDEA: Inspect actor to make sure it has a static mesh component
  @unreal-value{
      var x = @(->unreal-value actor)
              
      x.StaticMeshComponent.SetSimulatePhysics(true);
      x.StaticMeshComponent.SetEnableGravity(true);

      x.StaticMeshComponent.SetMobility('Movable');

      return x
  })