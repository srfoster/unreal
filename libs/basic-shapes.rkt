#lang at-exp racket/base

(provide cube)

(require unreal)


(define (cube)
   @unreal-value{
     const uclass = require('uclass')().bind(this,global);
  class MySMA extends StaticMeshActor {
   ctor() {
    this.StaticMeshComponent.SetStaticMesh(StaticMesh.Load('/Engine/BasicShapes/Cube.Cube'))
    this.StaticMeshComponent.SetMobility('Movable');
    }
  }      
  let MySMA_C = uclass(MySMA);
  
  return new MySMA_C(GWorld);
   })

(module+ main
  (require unreal/libs/physics)
  (unreal-eval-js
    (enable-physics (cube))))



