#lang at-exp racket

(provide bootstrap-unreal-js
         use-deprecated-unreal-webserver)

(define use-deprecated-unreal-webserver (make-parameter #f))

;Experimental: Trying to use unreal.js websockets to replace Isaratech webserver
;  Currently cannot get 'received' to print when sending from Racket or Chrome's websocket client :(
(define (bootstrap-unreal-js folder)
  (if (use-deprecated-unreal-webserver)
      (deprecated-bootstrap-unreal-js folder)
      (with-output-to-file #:exists 'replace
        (build-path folder "on-start.js")
        (thunk
         (displayln
          @~a{

 var evaluatedThings = {}
                       
 function nextId(){
  return "id:"+Math.random();
 }
 
 function simplify(val){
  if(!val) return val;
  
  if(val.GetDisplayName){
   return {type: "actor", id: val.GetDisplayName()}
  }
  
  if(val.map){
   return val.map(simplify)
  }
  
  return val
 }
 
 
 //The minimal code to allow for Aether->World Crossing.
 function main(){
  console.log("**************Unreal TCP Server Started************")
  
  class MyTCP extends Root.ResolveClass('TCP'){
   MessageReceived(racketMessage){

    let messages = racketMessage.split("\n")
    messages.map((racketMessage) => {
     console.log(racketMessage)
     racketMessage = JSON.parse(racketMessage)
     console.log("In MessageReceived(racketMessage)")
     console.log(racketMessage)

     var val;

     try {
      val = eval(racketMessage["jsSnippet"])
      } catch (e) {
      console.log(racketMessage)
      console.log(e)
      val = { type: "error", error: e.toString() }
     }

     var payload = `{"eventType": ${racketMessage["eventType"]}, "eventData": ${JSON.stringify(simplify(val))}}`

     console.log(payload)

     this.SendMessage(payload + "\n")
     })
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
  
  let MyTCP_C = require('uclass')()(global,MyTCP);
  let s = new MyTCP_C(GWorld,{X:7360.0,Y:3860.0,Z:7296.0},{Yaw:180});
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

 })))))


(define (deprecated-bootstrap-unreal-js folder)
  (with-output-to-file #:exists 'replace
    (build-path folder "on-start.js")
    (thunk
     (displayln
     @~a{
 var evaluatedThings = {}

 function nextId(){
  return "id:"+Math.random();
 }

 function simplify(val){
  if(!val) return val;
  
  if(val.GetDisplayName){
    return {type: "actor", id: val.GetDisplayName()}
  }

  if(val.map){
    return val.map(simplify)
  }

  return val
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
    //console.log("script",script)

    var val = eval(script)

    var payload = JSON.stringify(simplify(val))

    //console.log(payload)
    
    var resp = new Response.ConstructResponseExt()
    resp.SetResponseContent(payload)
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