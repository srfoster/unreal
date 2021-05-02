#lang racket/base

(require racket/tcp racket/match racket/string json racket/format)

(provide send-to-unreal 
         wait-until-unreal-is-running
         unreal-is-running?)

(define (send-to-unreal string)
;  (displayln (~a "Sending to Unreal " string))
  (when (not connection-thread)
    (start-connection-thread))

  (thread-send connection-thread (list string (current-thread)))
  (thread-receive))

(define (unreal-is-running?)
  (define the-listener (tcp-listen 8888 5 #t))
  (define in-port #f)
  (define out-port #f)
  (define connection-made? #f)
  (define test-thread (thread (lambda () 
                                (displayln "Testing to see if unreal is alive....")
                                (define-values (in out) (tcp-accept the-listener))
                                (set! in-port in)
                                (set! out-port out)
                                (set! connection-made? #t))))
  
  (sleep 1)
  (for ([i (in-range 0 7)]) ; Wait a few seconds for unreal to make contact
    #:break connection-made?
    (sleep 1)
    (displayln "Waiting..."))

  (tcp-close the-listener)
  (when out-port (close-output-port out-port))
  (when in-port (close-input-port in-port))

  (displayln (if connection-made? "Yes, alive" "Not alive"))
        
  (kill-thread test-thread)
  
  connection-made?)
  
(define (wait-until-unreal-is-running)
  (displayln "Waiting for unreal to start...")            
  (define result (send-to-unreal "(()=>{return 'hi'})()"))

  (if (string=? "hi" result)
      #t
      (let ()
        (displayln "Unreal connection failed, retrying in five seconds")
        (sleep 5)
        (wait-until-unreal-is-running))))

;Other threads can send to the connection-thread's queue, e.g.
#;
(for ([i (in-naturals)])
  (thread-send connection-thread (~a "(()=>{return {X: " i "}})()"))
  (sleep 1))

(define connection-thread #f)

(define (start-connection-thread)
  (set! connection-thread
        (thread
         (lambda ()
          (let main-loop ()
            (displayln "Creating listener...")
            (define the-listener (tcp-listen 8888 5 #t))
            (displayln "Accepting connection...")
            (define-values (in out) (tcp-accept the-listener))
            (displayln "Accepted connection!")
            
            (let loop ()
              ;(displayln "Sending...")
              (match-define (list message calling-thread) (thread-receive))
              (displayln message out)
              (flush-output out)
              ;(displayln "Reading...")
              (define resp (with-handlers ([exn:fail:network:errno? (lambda (e)
                                                                      (displayln (exn-message e))
                                                                      (displayln (exn:fail:network:errno-errno e))
                                                                      (displayln (exn-continuation-marks e))
                                                                      eof)])
                             (string-trim (read-line in))))
              ;(displayln resp)
              (thread-send calling-thread (string->jsexpr resp))
              (when (not (eof-object? resp))
                (loop)))
            
            (displayln "Closing...")
            (tcp-close the-listener)
            
            (sleep 1)
            (main-loop))))))


