#lang racket

(require racket/tcp racket/match racket/string json racket/format data/queue)

(provide send-to-unreal 
         wait-until-unreal-is-running
         unreal-is-running?
         subscribe-to-unreal-event
         unsubscribe-from-unreal-event
         unsubscribe-all-from-unreal-event)

; hash of eventTypes : functions
(define subscribed-events
  (make-hash))

; hash of groupNames : functions
(define subscription-groups
  (make-hash))

(define (subscribe-to-unreal-event event-type func #:group [group #f])
  (displayln "Subscribing new event...")
  (if (hash-has-key? subscribed-events event-type)
      (hash-set! subscribed-events event-type (cons func (hash-ref subscribed-events event-type)))
      (hash-set! subscribed-events event-type (list func)))
  (if (hash-has-key? subscription-groups group)
      (hash-set! subscription-groups group (cons func (hash-ref subscription-groups group)))
      (hash-set! subscription-groups group (list func))))

(define (unsubscribe-from-unreal-event event-type func)
  (when (hash-has-key? subscribed-events event-type)
        (hash-set! subscribed-events event-type (remove func (hash-ref subscribed-events event-type)))))

(define (unsubscribe-all-from-unreal-event event-type #:group [group #f])
  
  (when (hash-has-key? subscribed-events event-type)
    (define functions-subscribed-to-event-type (hash-ref subscribed-events event-type))
    (define is-not-in-group?
      (lambda (f)
        (not (member f (hash-ref subscription-groups group (list))))))
    (define functions-subscribed-to-event-type-and-not-in-group 
      (filter is-not-in-group?
              functions-subscribed-to-event-type))

    (hash-set! subscribed-events event-type functions-subscribed-to-event-type-and-not-in-group)))

(define (wait-until-unreal-is-running)
  (displayln "Waiting for unreal to start...")            
  (define result (send-to-unreal "(()=>{return 'hi'})()"))

  (if (string=? "hi" result)
      #t
      (let ()
        (displayln "Unreal connection failed, retrying in five seconds")
        (sleep 5)
        (wait-until-unreal-is-running))))

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
  

(define (send-to-unreal js-snippet)
   (displayln (~a "Sending to Unreal " js-snippet))
  (when (or (not connection-thread) (not (thread-running? connection-thread)))
    (start-connection-thread))
  (when (or (not message-handling-thread) (not (thread-running? message-handling-thread)))
    (start-message-handling-thread))

  (let loop ()
    (when (not unreal-tcp-out)
      (sleep 0.1)
      (displayln "Waiting for Racket's unreal handling threads to start...")
      (loop)))

  (define unique-id (random))
  (define message (hash 'eventType unique-id 'jsSnippet js-snippet))
  (displayln (jsexpr->string message) unreal-tcp-out)
  (flush-output unreal-tcp-out)
  (define wait (make-channel))
  (subscribe-to-unreal-event unique-id(lambda (resp) 
    (channel-put wait resp)
  ))
  (displayln (~a "waiting for response for " unique-id))
  (define resp (channel-get wait))
  (displayln resp)
  resp
  )


(define unreal-message-queue 
  (make-queue))

(define message-handling-thread #f)

(define (start-message-handling-thread)
  (set! message-handling-thread
        (thread 
          (lambda ()
            (let main-loop ()
              (if (queue-empty? unreal-message-queue)
                (let() 
                  (sleep 0.1))
                (let ()
                  (displayln "Handling message..." )
                  (define unreal-message (dequeue! unreal-message-queue))
                  (displayln unreal-message )
                  (define event-type (hash-ref unreal-message 'eventType))
                  (define functions-to-call
                    (hash-ref subscribed-events event-type '()))
                  (for ([f functions-to-call])
                    (displayln "Looping...")
                    (thread (thunk (f (hash-ref unreal-message 'eventData)))))
                  (when (number? event-type)
                        (hash-remove! subscribed-events event-type))


                  ; Unreal message will look like (hash 'event-type "projectile-hit"
                  ;                                     'event-data (hash 'X 345 'Y 345 'Z 345))
                  ; OR it will look like (hash 'event-type 23
                  ;                            'event-data #t ) 
                  ; The former is for events generated in Unreal
                  ; the latter is for responses to unreal-eval-js; 
                  ) 
              )
              (main-loop)
              )))))

(define connection-thread #f)
(define unreal-tcp-out #f)

(define (start-connection-thread)
  (set! connection-thread
        (thread
         (lambda ()
          (let main-loop ()
            (displayln "Creating listener...")
            (define the-listener (tcp-listen 8888 5 #t))
            (displayln "Accepting connection...")
            (define-values (in out) (tcp-accept the-listener))
            (set! unreal-tcp-out out)
            (displayln "Accepted connection!")
            
            (let loop ()
              (define raw-message-from-unreal (with-handlers ([exn:fail:network:errno? (lambda (e)
                                                                      (displayln (exn-message e))
                                                                      (displayln (exn:fail:network:errno-errno e))
                                                                      (displayln (exn-continuation-marks e))
                                                                      eof)])
                                                              
                             (string-trim (read-line in))))
              ; (when (eof-object? raw-message-from-unreal)
              ;   (set! unreal-tcp-out #f)
              ;   (set! connection-thread #f)
              ;   (set! message-handling-thread #f)
              ;  )

              (displayln "raw-message-from-unreal")
              (displayln raw-message-from-unreal)

              (when (not (eof-object? raw-message-from-unreal))
                (define message-from-unreal
                  (with-handlers ([exn:fail? (lambda (e)
                                               (displayln e)
                                               (void))])
                    (string->jsexpr raw-message-from-unreal)))
                (displayln "Enqueuing message...")
                (displayln message-from-unreal)
                (when (not (void? message-from-unreal))
                  (enqueue! unreal-message-queue message-from-unreal))
                (loop)))
            
            (displayln "Closing...")
            (tcp-close the-listener)
            
            (sleep 1)
            (main-loop))))))