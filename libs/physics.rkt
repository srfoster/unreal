#lang at-exp racket/base

(provide enable-physics
         radial-force
         force )

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

(define (radial-force radius force-strength )
  @unreal-value{
 var r = new RadialForceActor(GWorld)

 r.ForceComponent.ForceStrength = @(->unreal-value force-strength)
 r.ForceComponent.Radius = @(->unreal-value radius)

 return r
 })

(define (force spawn x y z)
  @unreal-value{
 var spawn = @(->unreal-value spawn);
 var scm = spawn.StaticMeshComponent
 scm.AddImpulse({X:@x,Y:@y,Z:@z})
 
 return true
 })
