
#lang racket/base

;Trying to factor out the runtime into something we could
;  move into another package.
;Ideally, we would even drop the assumptions about spells and spell server, etc.

(provide add-spawn!
         get-spawn
         get-spell
         run-spell
         get-errors
         seconds-between-ticks
         spell-language-module 
         )

(require racket/function
         racket/string
         racket/contract
         racket/format
         racket/list)

;Can't run programs unless you have a spawn.  A visualization of the "computer" running the programs.
;  TODO: Pivot to a better name than spawn.
(define current-spawns (hash))      
(define current-programs (hash))
(define current-errors (hash))

(define runner #f)
(define seconds-between-ticks (make-parameter 0.1))

(define (add-spawn! name spawn)
  (set! current-spawns (hash-set current-spawns name spawn)))

(define (get-spawn name)
  (hash-ref current-spawns name #f))

(define (get-errors name)
  (hash-ref current-errors name '()))

(define (handle-spell-error username e) 
  (if (program-stopped-working? e)
      (let ()
        (set! current-programs
              (hash-remove current-programs
                           username)))
      (let ()
        (set! current-errors
              (hash-update current-errors
                           username
                           (lambda (es)
                             (cons e es))))))) 

(define (tick-program username)
  (define program (hash-ref current-programs username))
  
  (with-handlers
      ([exn? (curry handle-spell-error username)])
    ;User's program is implemented as a generator, so we 
    ; call it as a function to tick it
    (program)))

(define spell-language-module (make-parameter #f))

(require racket/sandbox)
(define safe-ns #f)
(define sandbox-eval #f)
(define (setup-ns)
  (when (not (spell-language-module))
    (raise-user-error "Please set the spell-language-module parameter"))
  
  (define main-ns (current-namespace))
  
  (when (not sandbox-eval) 
    (sandbox-namespace-specs
     (let ([specs (sandbox-namespace-specs)])
       `(,(car specs)
         ,@(cdr specs)
         unreal)))
    
    (set! sandbox-eval (make-evaluator (spell-language-module))))

#;
  (set! safe-ns
        (let ([new-ns (make-empty-namespace)])
          (namespace-require  (spell-language-module) new-ns))
   
        #;
        (let () 
          (dynamic-require (spell-language-module) #f)
          (module->namespace (spell-language-module))))
          
  ;(namespace-attach-module safe-ns (spell-language-module) main-ns)
  )


(define (setup-ticking-thread)
  (when (not runner)
    (set! runner
          (thread
           (thunk
            (let tick ()
              ;clear screen and move cursor home
              (display "\033[2J\033[H") 
              (for ([username (in-hash-keys current-programs)])
                (display username)
                (tick-program username))
              
              ;move cursor home
              (display "\033[H")
              
              (for ([username (in-hash-keys current-errors)])
                (when (not (empty? (get-errors username)))
                  (define err-msg 
                    (string-join 
                     (string-split 
                      (~a (last (get-errors username))) "\n")
                     "\033[1E\033[40C"))
                  (display 
                   (~a "\033[40C" username " ERROR!\033[1E\033[40C" err-msg "\033[2E"))))
              
              (displayln "\033[H")

              (sleep (seconds-between-ticks))
              (tick)))))))

(define (setup-ns-and-ticking-thread)
  (displayln "Setting up run-lang namespace and ticker")
  (setup-ns)  
  (setup-ticking-thread)
  (displayln "run-lang and ticker setup complete"))

(define (program-stopped-working? e)
  (define m (exn-message e))
  (string-contains? m "cannot call a running generator"))


(define/contract (get-spell spell-id)
  (-> integer? list?)
  
  (local-require net/http-easy
                 json)
  
  (define id spell-id)
  
  (define res
    (get
     (~a "http://nexus.codespells.org:8080/secret/"
         id)))
  (define payload
    (response-json res))
  (define code-string
    (~a
     "(let () "
     (hash-ref payload 'text)
     ")"))
  (define code
    (read (open-input-string code-string)))
  
  code)

(define (run-spell spawn-name code args)
  (setup-ns-and-ticking-thread)
    
  (set! current-errors
        (hash-set current-errors
                  spawn-name
                  '()))
  
  (with-handlers
      ([exn? (curry handle-spell-error spawn-name)])
    
    (define program
      (sandbox-eval
       `(generator ()
                   (with-args ',args
                     (with-spawn ,(hash-ref current-spawns spawn-name)
                       ,code)))
      ; safe-ns
       ))
    
    (set! current-programs
          (hash-set current-programs
                    spawn-name 
                    program))


    ))

