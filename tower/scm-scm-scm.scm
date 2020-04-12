;; A meta-circular little Scheme v1.3 R02.04.12 by SUZUKI Hisao

;; Intrinsic:    ($Intrinsic . function)
;; Continuation: ($Continuation . function)
;; Closure:      ($Closure params body env)

(define fst car)
(define snd (lambda (x) (car (cdr x))))
(define trd (lambda (x) (car (cdr (cdr x)))))
(define None (set! fst fst))
(define exit-with #f)               ; to be set at global-eval

(define _error
  (lambda (reason arg)
    (display "Error: ") (display reason) (display ": ") (display arg)
    (newline)
    (exit-with None)))

;; (_ CAR_ CDR_) returns a mutable cell to construct environments.
;; (define x (_ 'a 'b))
;; (x 'car) => a
;; (x 'cdr) => b
;; (x '(c)) => None; (x 'cdr) = c
(define _
  (lambda (CAR_ CDR_)
    (lambda (op)
      (if (eq? op 'car)
          CAR_
        (if (eq? op 'cdr)
            CDR_
          (if (pair? op)
              (set! CDR_ (car op))
            (_error "unknown op" op)))))))

;; Return a list of keys of the global environment.
(define globals
  (lambda (loop)
    (set! loop (lambda (env result)
                 (if (null? env)
                     result
                   (loop (env 'cdr)
                         (cons ((env 'car) 'car)
                               result)))))
    (loop (Global-Env 'cdr) '()))) ; Take cdr to skip the frame marker.

(define _i
  (lambda (name fun)
    (_ name (cons '$Intrinsic fun))))

(define Global-Env
  (_ (_i '< (lambda (x) (< (fst x) (snd x))))
     (_ (_i '= (lambda (x) (= (fst x) (snd x))))
        (_ (_i 'number? (lambda (x) (number? (fst x))))
           (_ (_i 'error (lambda (x) (_error (fst x) (snd x)))) ; cf. SRFI-23
              (_ (_i 'globals globals)
                 '()))))))

(set! Global-Env
      (_ (_i 'display (lambda (x) (display (fst x))))
         (_ (_i 'newline (lambda (x) (newline)))
            (_ (_i 'read (lambda (x) (read)))
               (_ (_i 'eof-object? (lambda (x) (eof-object? (fst x))))
                  (_ (_i 'symbol? (lambda (x) (symbol? (fst x))))
                     (_ (_ 'call/cc 'call/cc)
                        (_ (_ 'apply 'apply)
                           (_ (_i '+ (lambda (x) (+ (fst x) (snd x))))
                              (_ (_i '- (lambda (x) (- (fst x) (snd x))))
                                 (_ (_i '* (lambda (x) (* (fst x) (snd x))))
                                    Global-Env)))))))))))

(set! Global-Env
      (_ (_ '() '())                    ; frame marker
         (_ (_i 'car (lambda (x) (car (fst x))))
            (_ (_i 'cdr (lambda (x) (cdr (fst x))))
               (_ (_i 'cons (lambda (x) (cons (fst x) (snd x))))
                  (_ (_i 'eq? (lambda (x) (eq? (fst x) (snd x))))
                     (_ (_i 'pair? (lambda (x) (pair? (fst x))))
                        (_ (_i 'null? (lambda (x) (null? (fst x))))
                           (_ (_i 'not (lambda (x) (not (fst x))))
                              (_ (_i 'list (lambda (x) x))
                                 Global-Env))))))))))

;; Evaluate an expression with an environment and a continuation.
(define evaluate
  (lambda (exp env k)
    (if (pair? exp)
        ((lambda (kar kdr)
           (if (eq? kar 'quote)         ; (quote e)
               (k (fst kdr))
             (if (eq? kar 'if)          ; (if e1 e2) or (if e1 e2 e3)
                 (if (null? (cdr (cdr kdr)))
                     (evaluate (fst kdr) env
                               (lambda (x)
                                 (if x
                                     (evaluate (snd kdr) env k)
                                   (evaluate None env k))))
                   (evaluate (fst kdr) env
                             (lambda (x)
                               (if x
                                   (evaluate (snd kdr) env k)
                                 (evaluate (trd kdr) env k)))))
               (if (eq? kar 'begin)     ; (begin e...)
                   (eval-sequentially kdr env k)
                 (if (eq? kar 'lambda)  ; (lambda (v...) e...)
                     (k (list '$Closure (car kdr) (cdr kdr) env))
                   (if (eq? kar 'define) ; (define v e)
                       (evaluate (snd kdr) env
                                 (lambda (x)
                                   (k (define-var (fst kdr) x env))))
                     (if (eq? kar 'set!) ; (set! v e)
                         (evaluate (snd kdr) env
                                   (lambda (x)
                                     (k (set-var (look-for-pair (fst kdr) env)
                                                 x))))
                       (if (eq? kar '$Intrinsic)
                           (k exp)
                         (if (eq? kar '$Continuation)
                             (k exp)
                           (if (eq? kar '$Closure)
                               (k exp)
                             (evaluate kar env
                                       (lambda (fun)
                                         (evlis kdr env
                                                (lambda (arg)
                                                  (apply-fun fun arg k)
                                                  ))))))))))))))
         (car exp)                      ; = kar
         (cdr exp))                     ; = kdr
      (if (symbol? exp)
          (k ((look-for-pair exp env) 'cdr))
        (k exp)))))                     ; as a number, #t, #f etc.

;; Apply a function to arguments with a continuation.
(define apply-fun
  (lambda (fun arg k)
    (if (eq? fun 'call/cc)
        (apply-fun (fst arg) (list (cons '$Continuation k)) k)
      (if (eq? fun 'apply)
          (apply-fun (fst arg) (snd arg) k)
        (if (pair? fun)
            ((lambda (kar kdr)
               (if (eq? kar '$Intrinsic)
                   (k (kdr arg))
                 (if (eq? kar '$Continuation)
                     (kdr (fst arg))
                   (if (eq? kar '$Closure)
                       (eval-sequentially
                        (snd kdr)       ; body
                        (_ (_ '() '())  ; frame marker
                           (prepend-defs-to-env (fst kdr) ; params
                                                arg
                                                (trd kdr))) ; env
                        k)
                     (_error "unknown functional pair" fun)))))
             (car fun)
             (cdr fun))
          (_error "unknown function" fun))))))

;; Evaluate each element of list sequentially to yield the last result.
(define eval-sequentially
  (lambda (explist env k)
    (evaluate (car explist) env
              (if (null? (cdr explist))
                  k
                (lambda (x) (eval-sequentially (cdr explist) env k))))))

;; Evaluate each element of list to construct a new list of the results.
;; (evlis '((* 1 2) (* 3 4)) Global-Env list) => (list '(2 12)) => ((2 12))
(define evlis
  (lambda (arg env k)
    (if (null? arg)
        (k '())
      (evaluate (car arg) env
                (lambda (head)
                  (evlis (cdr arg) env
                         (lambda (tail)
                           (k (cons head tail)))))))))

;; env = (_ (_ '() '()) x); (deinfe-var 'a 1 env) => None;
;; env = (_ (_ '() '()) (_ (_ a 1) x))
(define define-var
  (lambda (v e env)
    (if (null? ((env 'car) 'car))       ; Check for the frame marker.
        (env (list (_ (_ v e)
                      (env 'cdr))))
      (_error "illegal frame marker" ((env 'car) 'car)))))

;; x = (_ a 1); (set-var x 2) => None; x = (_ a 2)
(define set-var
  (lambda (pair e)
    (pair (list e))))

;; (look-for-pair 'b (_ (_ a 1) (_ (_ b 2) (_ (_ c 3) 'nil)))) => (_ b 2)
(define look-for-pair
  (lambda (key alist)
    (if (null? alist)
        (_error "not found" key)
      (if (eq? key ((alist 'car) 'car))
          (alist 'car)
        (look-for-pair key (alist 'cdr))))))

;; (prepend-defs-to-env '(a b) '(1 2) x) => (_ (_ a 1) (_ (_ b 1) x))
(define prepend-defs-to-env
  (lambda (keys data env)
    (if (null? keys)
        env
      (_ (_ (car keys) (car data))
         (prepend-defs-to-env (cdr keys) (cdr data) env)))))

;; Evaluate an expression in the global environment.
(define global-eval
  (lambda (exp)
    (call/cc (lambda (k)
               (set! exit-with k)
               (evaluate exp Global-Env (lambda (x) x))))))

;; Repeat read-eval-print until End-of-File.
(define read-eval-print-loop
  (lambda ()
    ((lambda (input)
       (if (not (eof-object? input))
           (begin
             ((lambda (result)
                (if (not (eq? result None))
                    (begin
                      (display "=> ") (display result)
                      (newline))))
              (global-eval input))
             (read-eval-print-loop))))
     (read))))

;; (read-eval-print-loop)
(global-eval '(begin
;; A meta-circular little Scheme v1.3 R02.04.12 by SUZUKI Hisao

;; Intrinsic:    ($Intrinsic . function)
;; Continuation: ($Continuation . function)
;; Closure:      ($Closure params body env)

(define fst car)
(define snd (lambda (x) (car (cdr x))))
(define trd (lambda (x) (car (cdr (cdr x)))))
(define None (set! fst fst))
(define exit-with #f)               ; to be set at global-eval

(define _error
  (lambda (reason arg)
    (display "Error: ") (display reason) (display ": ") (display arg)
    (newline)
    (exit-with None)))

;; (_ CAR_ CDR_) returns a mutable cell to construct environments.
;; (define x (_ 'a 'b))
;; (x 'car) => a
;; (x 'cdr) => b
;; (x '(c)) => None; (x 'cdr) = c
(define _
  (lambda (CAR_ CDR_)
    (lambda (op)
      (if (eq? op 'car)
          CAR_
        (if (eq? op 'cdr)
            CDR_
          (if (pair? op)
              (set! CDR_ (car op))
            (_error "unknown op" op)))))))

;; Return a list of keys of the global environment.
(define globals
  (lambda (loop)
    (set! loop (lambda (env result)
                 (if (null? env)
                     result
                   (loop (env 'cdr)
                         (cons ((env 'car) 'car)
                               result)))))
    (loop (Global-Env 'cdr) '()))) ; Take cdr to skip the frame marker.

(define _i
  (lambda (name fun)
    (_ name (cons '$Intrinsic fun))))

(define Global-Env
  (_ (_i '< (lambda (x) (< (fst x) (snd x))))
     (_ (_i '= (lambda (x) (= (fst x) (snd x))))
        (_ (_i 'number? (lambda (x) (number? (fst x))))
           (_ (_i 'error (lambda (x) (_error (fst x) (snd x)))) ; cf. SRFI-23
              (_ (_i 'globals globals)
                 '()))))))

(set! Global-Env
      (_ (_i 'display (lambda (x) (display (fst x))))
         (_ (_i 'newline (lambda (x) (newline)))
            (_ (_i 'read (lambda (x) (read)))
               (_ (_i 'eof-object? (lambda (x) (eof-object? (fst x))))
                  (_ (_i 'symbol? (lambda (x) (symbol? (fst x))))
                     (_ (_ 'call/cc 'call/cc)
                        (_ (_ 'apply 'apply)
                           (_ (_i '+ (lambda (x) (+ (fst x) (snd x))))
                              (_ (_i '- (lambda (x) (- (fst x) (snd x))))
                                 (_ (_i '* (lambda (x) (* (fst x) (snd x))))
                                    Global-Env)))))))))))

(set! Global-Env
      (_ (_ '() '())                    ; frame marker
         (_ (_i 'car (lambda (x) (car (fst x))))
            (_ (_i 'cdr (lambda (x) (cdr (fst x))))
               (_ (_i 'cons (lambda (x) (cons (fst x) (snd x))))
                  (_ (_i 'eq? (lambda (x) (eq? (fst x) (snd x))))
                     (_ (_i 'pair? (lambda (x) (pair? (fst x))))
                        (_ (_i 'null? (lambda (x) (null? (fst x))))
                           (_ (_i 'not (lambda (x) (not (fst x))))
                              (_ (_i 'list (lambda (x) x))
                                 Global-Env))))))))))

;; Evaluate an expression with an environment and a continuation.
(define evaluate
  (lambda (exp env k)
    (if (pair? exp)
        ((lambda (kar kdr)
           (if (eq? kar 'quote)         ; (quote e)
               (k (fst kdr))
             (if (eq? kar 'if)          ; (if e1 e2) or (if e1 e2 e3)
                 (if (null? (cdr (cdr kdr)))
                     (evaluate (fst kdr) env
                               (lambda (x)
                                 (if x
                                     (evaluate (snd kdr) env k)
                                   (evaluate None env k))))
                   (evaluate (fst kdr) env
                             (lambda (x)
                               (if x
                                   (evaluate (snd kdr) env k)
                                 (evaluate (trd kdr) env k)))))
               (if (eq? kar 'begin)     ; (begin e...)
                   (eval-sequentially kdr env k)
                 (if (eq? kar 'lambda)  ; (lambda (v...) e...)
                     (k (list '$Closure (car kdr) (cdr kdr) env))
                   (if (eq? kar 'define) ; (define v e)
                       (evaluate (snd kdr) env
                                 (lambda (x)
                                   (k (define-var (fst kdr) x env))))
                     (if (eq? kar 'set!) ; (set! v e)
                         (evaluate (snd kdr) env
                                   (lambda (x)
                                     (k (set-var (look-for-pair (fst kdr) env)
                                                 x))))
                       (if (eq? kar '$Intrinsic)
                           (k exp)
                         (if (eq? kar '$Continuation)
                             (k exp)
                           (if (eq? kar '$Closure)
                               (k exp)
                             (evaluate kar env
                                       (lambda (fun)
                                         (evlis kdr env
                                                (lambda (arg)
                                                  (apply-fun fun arg k)
                                                  ))))))))))))))
         (car exp)                      ; = kar
         (cdr exp))                     ; = kdr
      (if (symbol? exp)
          (k ((look-for-pair exp env) 'cdr))
        (k exp)))))                     ; as a number, #t, #f etc.

;; Apply a function to arguments with a continuation.
(define apply-fun
  (lambda (fun arg k)
    (if (eq? fun 'call/cc)
        (apply-fun (fst arg) (list (cons '$Continuation k)) k)
      (if (eq? fun 'apply)
          (apply-fun (fst arg) (snd arg) k)
        (if (pair? fun)
            ((lambda (kar kdr)
               (if (eq? kar '$Intrinsic)
                   (k (kdr arg))
                 (if (eq? kar '$Continuation)
                     (kdr (fst arg))
                   (if (eq? kar '$Closure)
                       (eval-sequentially
                        (snd kdr)       ; body
                        (_ (_ '() '())  ; frame marker
                           (prepend-defs-to-env (fst kdr) ; params
                                                arg
                                                (trd kdr))) ; env
                        k)
                     (_error "unknown functional pair" fun)))))
             (car fun)
             (cdr fun))
          (_error "unknown function" fun))))))

;; Evaluate each element of list sequentially to yield the last result.
(define eval-sequentially
  (lambda (explist env k)
    (evaluate (car explist) env
              (if (null? (cdr explist))
                  k
                (lambda (x) (eval-sequentially (cdr explist) env k))))))

;; Evaluate each element of list to construct a new list of the results.
;; (evlis '((* 1 2) (* 3 4)) Global-Env list) => (list '(2 12)) => ((2 12))
(define evlis
  (lambda (arg env k)
    (if (null? arg)
        (k '())
      (evaluate (car arg) env
                (lambda (head)
                  (evlis (cdr arg) env
                         (lambda (tail)
                           (k (cons head tail)))))))))

;; env = (_ (_ '() '()) x); (deinfe-var 'a 1 env) => None;
;; env = (_ (_ '() '()) (_ (_ a 1) x))
(define define-var
  (lambda (v e env)
    (if (null? ((env 'car) 'car))       ; Check for the frame marker.
        (env (list (_ (_ v e)
                      (env 'cdr))))
      (_error "illegal frame marker" ((env 'car) 'car)))))

;; x = (_ a 1); (set-var x 2) => None; x = (_ a 2)
(define set-var
  (lambda (pair e)
    (pair (list e))))

;; (look-for-pair 'b (_ (_ a 1) (_ (_ b 2) (_ (_ c 3) 'nil)))) => (_ b 2)
(define look-for-pair
  (lambda (key alist)
    (if (null? alist)
        (_error "not found" key)
      (if (eq? key ((alist 'car) 'car))
          (alist 'car)
        (look-for-pair key (alist 'cdr))))))

;; (prepend-defs-to-env '(a b) '(1 2) x) => (_ (_ a 1) (_ (_ b 1) x))
(define prepend-defs-to-env
  (lambda (keys data env)
    (if (null? keys)
        env
      (_ (_ (car keys) (car data))
         (prepend-defs-to-env (cdr keys) (cdr data) env)))))

;; Evaluate an expression in the global environment.
(define global-eval
  (lambda (exp)
    (call/cc (lambda (k)
               (set! exit-with k)
               (evaluate exp Global-Env (lambda (x) x))))))

;; Repeat read-eval-print until End-of-File.
(define read-eval-print-loop
  (lambda ()
    ((lambda (input)
       (if (not (eof-object? input))
           (begin
             ((lambda (result)
                (if (not (eq? result None))
                    (begin
                      (display "=> ") (display result)
                      (newline))))
              (global-eval input))
             (read-eval-print-loop))))
     (read))))

;; (read-eval-print-loop)
(global-eval '(begin
;; A meta-circular little Scheme v1.3 R02.04.12 by SUZUKI Hisao

;; Intrinsic:    ($Intrinsic . function)
;; Continuation: ($Continuation . function)
;; Closure:      ($Closure params body env)

(define fst car)
(define snd (lambda (x) (car (cdr x))))
(define trd (lambda (x) (car (cdr (cdr x)))))
(define None (set! fst fst))
(define exit-with #f)               ; to be set at global-eval

(define _error
  (lambda (reason arg)
    (display "Error: ") (display reason) (display ": ") (display arg)
    (newline)
    (exit-with None)))

;; (_ CAR_ CDR_) returns a mutable cell to construct environments.
;; (define x (_ 'a 'b))
;; (x 'car) => a
;; (x 'cdr) => b
;; (x '(c)) => None; (x 'cdr) = c
(define _
  (lambda (CAR_ CDR_)
    (lambda (op)
      (if (eq? op 'car)
          CAR_
        (if (eq? op 'cdr)
            CDR_
          (if (pair? op)
              (set! CDR_ (car op))
            (_error "unknown op" op)))))))

;; Return a list of keys of the global environment.
(define globals
  (lambda (loop)
    (set! loop (lambda (env result)
                 (if (null? env)
                     result
                   (loop (env 'cdr)
                         (cons ((env 'car) 'car)
                               result)))))
    (loop (Global-Env 'cdr) '()))) ; Take cdr to skip the frame marker.

(define _i
  (lambda (name fun)
    (_ name (cons '$Intrinsic fun))))

(define Global-Env
  (_ (_i '< (lambda (x) (< (fst x) (snd x))))
     (_ (_i '= (lambda (x) (= (fst x) (snd x))))
        (_ (_i 'number? (lambda (x) (number? (fst x))))
           (_ (_i 'error (lambda (x) (_error (fst x) (snd x)))) ; cf. SRFI-23
              (_ (_i 'globals globals)
                 '()))))))

(set! Global-Env
      (_ (_i 'display (lambda (x) (display (fst x))))
         (_ (_i 'newline (lambda (x) (newline)))
            (_ (_i 'read (lambda (x) (read)))
               (_ (_i 'eof-object? (lambda (x) (eof-object? (fst x))))
                  (_ (_i 'symbol? (lambda (x) (symbol? (fst x))))
                     (_ (_ 'call/cc 'call/cc)
                        (_ (_ 'apply 'apply)
                           (_ (_i '+ (lambda (x) (+ (fst x) (snd x))))
                              (_ (_i '- (lambda (x) (- (fst x) (snd x))))
                                 (_ (_i '* (lambda (x) (* (fst x) (snd x))))
                                    Global-Env)))))))))))

(set! Global-Env
      (_ (_ '() '())                    ; frame marker
         (_ (_i 'car (lambda (x) (car (fst x))))
            (_ (_i 'cdr (lambda (x) (cdr (fst x))))
               (_ (_i 'cons (lambda (x) (cons (fst x) (snd x))))
                  (_ (_i 'eq? (lambda (x) (eq? (fst x) (snd x))))
                     (_ (_i 'pair? (lambda (x) (pair? (fst x))))
                        (_ (_i 'null? (lambda (x) (null? (fst x))))
                           (_ (_i 'not (lambda (x) (not (fst x))))
                              (_ (_i 'list (lambda (x) x))
                                 Global-Env))))))))))

;; Evaluate an expression with an environment and a continuation.
(define evaluate
  (lambda (exp env k)
    (if (pair? exp)
        ((lambda (kar kdr)
           (if (eq? kar 'quote)         ; (quote e)
               (k (fst kdr))
             (if (eq? kar 'if)          ; (if e1 e2) or (if e1 e2 e3)
                 (if (null? (cdr (cdr kdr)))
                     (evaluate (fst kdr) env
                               (lambda (x)
                                 (if x
                                     (evaluate (snd kdr) env k)
                                   (evaluate None env k))))
                   (evaluate (fst kdr) env
                             (lambda (x)
                               (if x
                                   (evaluate (snd kdr) env k)
                                 (evaluate (trd kdr) env k)))))
               (if (eq? kar 'begin)     ; (begin e...)
                   (eval-sequentially kdr env k)
                 (if (eq? kar 'lambda)  ; (lambda (v...) e...)
                     (k (list '$Closure (car kdr) (cdr kdr) env))
                   (if (eq? kar 'define) ; (define v e)
                       (evaluate (snd kdr) env
                                 (lambda (x)
                                   (k (define-var (fst kdr) x env))))
                     (if (eq? kar 'set!) ; (set! v e)
                         (evaluate (snd kdr) env
                                   (lambda (x)
                                     (k (set-var (look-for-pair (fst kdr) env)
                                                 x))))
                       (if (eq? kar '$Intrinsic)
                           (k exp)
                         (if (eq? kar '$Continuation)
                             (k exp)
                           (if (eq? kar '$Closure)
                               (k exp)
                             (evaluate kar env
                                       (lambda (fun)
                                         (evlis kdr env
                                                (lambda (arg)
                                                  (apply-fun fun arg k)
                                                  ))))))))))))))
         (car exp)                      ; = kar
         (cdr exp))                     ; = kdr
      (if (symbol? exp)
          (k ((look-for-pair exp env) 'cdr))
        (k exp)))))                     ; as a number, #t, #f etc.

;; Apply a function to arguments with a continuation.
(define apply-fun
  (lambda (fun arg k)
    (if (eq? fun 'call/cc)
        (apply-fun (fst arg) (list (cons '$Continuation k)) k)
      (if (eq? fun 'apply)
          (apply-fun (fst arg) (snd arg) k)
        (if (pair? fun)
            ((lambda (kar kdr)
               (if (eq? kar '$Intrinsic)
                   (k (kdr arg))
                 (if (eq? kar '$Continuation)
                     (kdr (fst arg))
                   (if (eq? kar '$Closure)
                       (eval-sequentially
                        (snd kdr)       ; body
                        (_ (_ '() '())  ; frame marker
                           (prepend-defs-to-env (fst kdr) ; params
                                                arg
                                                (trd kdr))) ; env
                        k)
                     (_error "unknown functional pair" fun)))))
             (car fun)
             (cdr fun))
          (_error "unknown function" fun))))))

;; Evaluate each element of list sequentially to yield the last result.
(define eval-sequentially
  (lambda (explist env k)
    (evaluate (car explist) env
              (if (null? (cdr explist))
                  k
                (lambda (x) (eval-sequentially (cdr explist) env k))))))

;; Evaluate each element of list to construct a new list of the results.
;; (evlis '((* 1 2) (* 3 4)) Global-Env list) => (list '(2 12)) => ((2 12))
(define evlis
  (lambda (arg env k)
    (if (null? arg)
        (k '())
      (evaluate (car arg) env
                (lambda (head)
                  (evlis (cdr arg) env
                         (lambda (tail)
                           (k (cons head tail)))))))))

;; env = (_ (_ '() '()) x); (deinfe-var 'a 1 env) => None;
;; env = (_ (_ '() '()) (_ (_ a 1) x))
(define define-var
  (lambda (v e env)
    (if (null? ((env 'car) 'car))       ; Check for the frame marker.
        (env (list (_ (_ v e)
                      (env 'cdr))))
      (_error "illegal frame marker" ((env 'car) 'car)))))

;; x = (_ a 1); (set-var x 2) => None; x = (_ a 2)
(define set-var
  (lambda (pair e)
    (pair (list e))))

;; (look-for-pair 'b (_ (_ a 1) (_ (_ b 2) (_ (_ c 3) 'nil)))) => (_ b 2)
(define look-for-pair
  (lambda (key alist)
    (if (null? alist)
        (_error "not found" key)
      (if (eq? key ((alist 'car) 'car))
          (alist 'car)
        (look-for-pair key (alist 'cdr))))))

;; (prepend-defs-to-env '(a b) '(1 2) x) => (_ (_ a 1) (_ (_ b 1) x))
(define prepend-defs-to-env
  (lambda (keys data env)
    (if (null? keys)
        env
      (_ (_ (car keys) (car data))
         (prepend-defs-to-env (cdr keys) (cdr data) env)))))

;; Evaluate an expression in the global environment.
(define global-eval
  (lambda (exp)
    (call/cc (lambda (k)
               (set! exit-with k)
               (evaluate exp Global-Env (lambda (x) x))))))

;; Repeat read-eval-print until End-of-File.
(define read-eval-print-loop
  (lambda ()
    ((lambda (input)
       (if (not (eof-object? input))
           (begin
             ((lambda (result)
                (if (not (eq? result None))
                    (begin
                      (display "=> ") (display result)
                      (newline))))
              (global-eval input))
             (read-eval-print-loop))))
     (read))))

(read-eval-print-loop)
))
))
