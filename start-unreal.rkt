#lang racket

(provide start-unreal
         unreal-server-port)

(require net/http-easy
         file/unzip)

(define unreal-server-port (make-parameter 8080))

(define the-thread #f)
(define (start-unreal some.exe)
    
  (when (not the-thread)
    (with-handlers ;Only start if there's not an instance running
        ([exn:fail:network:errno?
          (lambda (e)
            (set! the-thread
                  (thread
                   (thunk
                    (system
                     (~a some.exe
                         " -unreal-server=8080 -codespells-server=8081"))))))])
      (get (~a "127.0.0.1:" (unreal-server-port) "/js")
           #:close? #t))
    

    (wait-until-running)))


(define (wait-until-running)
  (with-handlers ;Only start if there's not an instance running
      ([exn:fail:network:errno?
        (lambda (e) ;Keep trying to start up
          (displayln (~a "No World server found at 127.0.0.1:" (unreal-server-port) ".  Trying again in 5 seconds..."))
          (sleep 5)

          (wait-until-running))
        ])
    (get (~a "127.0.0.1:" (unreal-server-port) "/js")
         #:close? #t)))