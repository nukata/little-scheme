# A Meta-circular Little Scheme

This is a meta-circular interpreter of a subset of Scheme, inspired by
[Zick Standard Lisp](https://github.com/zick/ZickStandardLisp).

It implements the same language as

- [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)
- [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)
- [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)
- [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)
- [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)

and runs on them.
It also runs on other Schemes such as
[guile](https://www.gnu.org/software/guile/).
It will run on any R5RS Schemes.



## How to use

Run `scm.scm` on another Scheme.

```
$ little-scheme-in-go scm.scm
(+ 5 6)
=> 11
(cons 'a (cons 'b 'c))
=> (a b . c)
(list
1
2
3
)
=> (1 2 3)
+
=> ($Intrinsic . #<(x):((+ (fst x) (snd x))):#<GlobalEnv>>)
(globals)
=> (globals = < * - + symbol? eof-object? read newline display error apply call/
cc list not null? pair? eqv? eq? cons cdr car)
```

Press EOF (e.g. Control-D) to exit the session.

## The implemented language

### Expression types

- _v_  [variable reference]

- (_e0_ _e1_...)  [procedure call]

- (`quote` _e_)  [`'`_e_ will be transformed into (`quote` _e_) when `read`]

- (`if` _e1_ _e2_ _e3_)  
  (`if` _e1_ _e2_)

- (`begin` _e_...)

- (`lambda` (_v_...) _e_...)

- (`set!` _v_ _e_)

- (`define` _v_ _e_)

For simplicity, this Scheme treats (`define` _v_ _e_) as an expression type.


### Built-in procedures

|                      |                          |                     |
|:---------------------|:-------------------------|:--------------------|
| (`car` _lst_)        | (`not` _x_)              | (`eof-object?` _x_) |
| (`cdr` _lst_)        | (`list` _x_ ...)         | (`symbol?` _x_)     |
| (`cons` _x_ _y_)     | (`call/cc` _fun_)        | (`+` _x_ _y_)       |
| (`eq?` _x_ _y_)      | (`apply` _fun_ _arg_)    | (`-` _x_ _y_)       |
| (`eqv?` _x_ _y_)     | (`display` _x_)          | (`*` _x_ _y_)       |
| (`pair?` _x_)        | (`newline`)              | (`<` _x_ _y_)       |
| (`null?` _x_)        | (`read`)                 | (`=` _x_ _y_)       |
|                      | (`error` _reason_ _arg_) | (`globals`)         |

- `(error` _reason_ _arg_`)` displays `Error:` _reason_`:` _arg_ and
  goes back to the top level.
  It is based on [SRFI-23](https://srfi.schemers.org/srfi-23/srfi-23.html).

- `(globals)` returns a list of keys of the global environment.
  It is not in the standard.

See [`Global-Env`](scm.scm#L50-L78)
in `scm.scm` for the implementation of the procedures
except `call/cc` and `apply`.  
`call/cc` and `apply` are implemented particularly at 
[`apply-fun`](scm.scm#L130-L154) in `scm.scm`.


## Examples

There are five files under the `examples` folder:

- [`fib90.scm`](examples/fib90.scm)
  calculates Fibonacci for 90 tail-recursively.

- [`nqueens.scm`](examples/nqueens.scm)
  solves N-Queens for 6.

- [`dynamic-wind-example.scm`](examples/dynamic-wind-example.scm)
  demonstrates the example of `dynamic-wind` in R5RS.

- [`amb.scm`](examples/amb.scm)
  demonstrates a non-deterministic evaluation with `call/cc`.

- [`yin-yang-puzzle.scm`](examples/yin-yang-puzzle.scm)
  runs the yin-yang puzzle with `call/cc`.

```
$ guile scm.scm < examples/fib90.scm 
2880067194370816120
$ guile scm.scm < examples/nqueens.scm
((5 3 1 6 4 2) (4 1 5 2 6 3) (3 6 2 5 1 4) (2 4 6 1 3 5))
$ guile scm.scm < examples/dynamic-wind-example.scm 
(connect talk1 disconnect connect talk2 disconnect)
$ guile scm.scm < examples/amb.scm
((1 A) (1 B) (1 C) (2 A) (2 B) (2 C) (3 A) (3 B) (3 C))
$ guile scm.scm < examples/yin-yang-puzzle.scm

*
**
***
****
*****
******
*******
********
*********
```

Press the interrupt key (e.g. Control-C) to stop the yin-yang puzzle.


## Tower of meta-circular interpreters

Being meta-circular, this interpreter is able to run itself recursively.

 1. Copy the interpeter file `scm.scm` to `scm-scm.scm`.

 2. Comment out the last line `(read-eval-print-loop)` of `scm-scm.scm`.

```Scheme
;; (read-eval-print-loop)
```

 3. Append two new lines `(global-eval '(begin` and `))` to `scm-scm.scm`.

```Scheme
;; (read-eval-print-loop)
(global-eval '(begin
))
```

 4. Insert the whole contents of `scm.scm` between the new lines.

```Scheme
;; (read-eval-print-loop)
(global-eval '(begin
;; A meta-circular little Scheme v1.1 R01.07.20 by SUZUKI Hisao
...
(read-eval-print-loop)
))
```

 5. Run `scm-scm.scm` on another Scheme.

For your convenience, I have built it as
[`tower/scm-scm.scm`](tower/scm-scm.scm).

```
$ little-scheme-in-go tower/scm-scm.scm
(+ 5 6)
=> 11
+
=> ($Intrinsic $Closure (x) ((+ (fst x) (snd x))) #<(op):((if (eq? op (quote car
)) CAR (if (eq? op (quote cdr)) CDR (if (pair? op) (set! CDR (car op)) (_error "
unknown op" op))))):#<| CAR CDR GlobalEnv>>)
```

Note that the _intrinsic_ function `+` is now implemented by a _closure_
of `scm.scm`, the underlying Scheme here.

You can repeat the above process any times.
Try [`tower/scm-scm-scm.scm`](tower/scm-scm-scm.scm) and you will find it runs
prohibitively _slowly_ as might be expected.

```
$ time little-scheme-in-go example/fib90.scm
2880067194370816120

real	0m0.007s
user	0m0.003s
sys	0m0.002s
$ time little-scheme-in-go scm.scm < example/fib90.scm
2880067194370816120

real	0m0.040s
user	0m0.032s
sys	0m0.007s
$ time little-scheme-in-go tower/scm-scm.scm < examples/fib90.scm
2880067194370816120

real	0m7.454s
user	0m8.140s
sys	0m0.079s
$ time little-scheme-in-go tower/scm-scm-scm.scm < examples/fib90.scm
2880067194370816120

real	41m31.453s
user	53m32.311s
sys	0m25.087s
$ 
```

I hope this serves as a good benchmark test for Scheme.
