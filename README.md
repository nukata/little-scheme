# A meta-circular Little Scheme

This is a meta-circular interpreter of a subset of Scheme.
It runs on
[little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)
(`scm.py`) and other Schemes.

## How to use

Run `scm.scm` in Scheme.

```
$ scm.py scm.scm
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
```

Press EOF (e.g. Control-D) to exit the session.


## Examples

There are four files under the `examples` folder, which
are copied from 
[little-scheme-in-python/examples](https://github.com/nukata/little-scheme-in-python/tree/v1.1.0/examples):

- [`fib90.scm`](examples/fib90.scm)
  calculates Fibonacci for 90 tail-recursively.

- [`nqueens.scm`](examples/nqueens.scm)
  runs an N-Queens solver for 6.

- [`dynamic-wind-example.scm`](examples/dynamic-wind-example.scm)
  demonstrates the example of `dynamic-wind` in R5RS.

- [`yin-yang-puzzle.scm`](examples/yin-yang-puzzle.scm)
  runs the yin-yang puzzle with `call/cc`.

```
$ scm.py scm.scm < examples/fib90.scm 
2880067194370816120
$ time pypy /usr/local/bin/scm.py scm.scm < examples/nqueens.scm
((5 3 1 6 4 2) (4 1 5 2 6 3) (3 6 2 5 1 4) (2 4 6 1 3 5))

real	0m3.704s
user	0m3.560s
sys	0m0.136s
$ scm.py scm.scm < examples/dynamic-wind-example.scm 
(connect talk1 disconnect connect talk2 disconnect)
$ scm.py scm.scm < examples/yin-yang-puzzle.scm

*
**
***
****
*****
******
*******
********
*********
**********
```

Press the interrupt key (e.g. Control-C) to stop the yin-yang puzzle.


## The implemented language

The language implemented here is the same as
[little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)
except for `load` and `symbol->string`, which are not implemented.

Additionally, it also has `globals`, which returns a list of keys of
the global environment.

```
(globals)
=> (globals = < * - + symbol? eof-object? read newline display apply call/cc list
 not null? pair? eqv? eq? cons cdr car)
```
