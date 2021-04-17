#lang at-exp racket

(provide bootstrap-unreal-js)

(define (bootstrap-unreal-js folder)
  (with-output-to-file #:exists 'replace
    (build-path folder "on-start.js")
    (thunk
     (displayln
     @~a{
 var evaluatedThings = {}

 function nextId(){
  return "id:"+Math.random();
 }

 //The minimal code to allow for Aether->World Crossing.
 //  Currently based on Isara tech's webserver.  Will need to change this to become more cross platform.
 function main(){
  console.log("**************Unreal Server Started************")

  class MyServer extends Root.ResolveClass('Server'){
   Eval(conn){
    console.log("In Eval(conn)")

    var script = conn.GetData()
    // var script = conn.GetGETVar("script")
    console.log("script",script)

    var val = eval(script)

    var serializedValue = undefined;

    var id = nextId();
    evaluatedThings[id] = val;

    console.log("ID...", id)
      
    //Is there an easier way to tell if something is some Unreal value?
    if(typeof(val) == "object" && !Array.isArray(val) && (""+val).match("_C]")){
                                
     // serializedValue = "(function(){return evaluatedThings['" + id + "']})()";                           
    } else {
      serializedValue = val;
    }

    var resp = new Response.ConstructResponseExt()
    resp.SetResponseContent(JSON.stringify({value: serializedValue, id: id}))
    conn.SendResponse(resp)
   }
   GetModDirectoryFromName(name){
    return {ModDirectory: modDirectories[name]}
   }
   GetUnrealServerPort(){
    let match = KismetSystemLibrary.GetCommandLine().match(/-unreal-server=(\d+)/)
    let port  = match ? match[1] : 8080
    return {Port: +port};
   }
   GetCodeSpellsServerPort(){
    let match = KismetSystemLibrary.GetCommandLine().match(/-codespells-server=(\d+)/)
    let port  = match ? match[1] : 8081
    return {Port: +port};
   }
  }

  let MyServer_C = require('uclass')()(global,MyServer);
  let s = new MyServer_C(GWorld,{X:7360.0,Y:3860.0,Z:7296.0},{Yaw:180});
  console.log("JS Server started!", s.GetUnrealServerPort().Port);

  return function () {
   s.DestroyActor()
  }
 }

 // bootstrap to initiate live-reloading dev env.
 try {
  module.exports = () => {

   let cleanup = null

   // wait for map to be loaded.
   process.nextTick(() => cleanup = main());

   // live-reloadable function should return its cleanup function
   return () => cleanup()
  }
 }
 catch (e) {
  console.log("Error",e);
  require('bootstrap')('on-start')
 }

 }))))