# A Meta-circular Little Scheme

This is a meta-circular interpreter of a subset of Scheme, inspired by
[Zick Standard Lisp](https://github.com/zick/ZickStandardLisp).

It implements the same language as

- [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)
- [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)
- [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)
- [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)
- [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)
- [little-scheme-in-lisp](https://github.com/nukata/little-scheme-in-lisp)
- [little-scheme-in-php](https://github.com/nukata/little-scheme-in-php)
- [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)
- [little-scheme-in-ruby](https://github.com/nukata/little-scheme-in-ruby)
- [little-scheme-in-typescript](https://github.com/nukata/little-scheme-in-typescript)

and runs on them.
It also runs on other Schemes such as
[guile](https://www.gnu.org/software/guile/) or any R5RS Schemes.



## How to use

Run `scm.scm` on another Scheme.
The following example uses [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go).

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


<a name="language"></a>
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


<a name="examples"></a>
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


<a name="performance"></a>
## Performance

The following table shows the times to run [`scm.scm`](scm.scm) `<` [`examples/nqueens.scm`](examples/nqueens.scm) on each Schemes.
I used MacBook Pro (15-inch, 2016), 2.6GHz Core i7, 16GB 2133MHz LPDDR3, macOS Mojave 10.14.6.

| Scheme                                                                                     | Compiled/Executed on                                  | Time [sec] | Rel. Speed |
|:-------------------------------------------------------------------------------------------|:------------------------------------------------------|-----------:|-----------:| 
| GNU Guile                                                                            2.2.7 | `guile`                                               |    0.14    |   14.8     |
| [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)                 1.1.1 | Go 1.14: `go build`                                   |    2.07    |    1.00    |
| [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)             1.0.0 | AdoptOpenJDK jdk-11.0.6+10: `make`                    |    2.09    |    0.99    |
| [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)       0.1.0 | Crystal 0.33.0: `crystal build --release scm.cr`      |    2.26    |    0.92    |
| [little-scheme-in-lisp](https://github.com/nukata/little-scheme-in-lispl)            0.3.0 | SBCL 2.0.2: `sbcl --script scm.l`                     |    2.51    |    0.82    |
| [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)                 1.0.2 | .NET Core 3.1.2: `dotnet build -c Release`            |    4.40    |    0.47    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.1.0 | PyPy 7.3.0 (Python 2.7.13): `pypy scm.py`             |    5.04    |    0.41    |
| [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)                 1.0.2 | Mono 6.8.0: `csc -o -r:System.Numerics.dll *.cs`      |    5.44    |    0.38    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.1.0 | PyPy 7.3.0 (Python 3.6.9): `pypy3 scm.py`             |    5.48    |    0.38    |
| [little-scheme-in-typescript](https://github.com/nukata/little-scheme-in-typescript) 1.1.1 | TypeScript 3.8.3/Node.js 13.11.0: `tsc -t ESNext ...` |   10.16    |    0.20    |
| [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)       0.1.0 | Crystal 0.33.0: `crystal scm.cr`                      |   10.94    |    0.19    |
| [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)             0.3.0 | Dart 2.7.1: `dart scm.dart`                           |   13.68    |    0.15    |
| [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)             0.3.0 | Dart 2.7.1: `dart2native scm.dart`; `./scm.exe`       |   14.20    |    0.15    |
| [little-scheme-in-php](https://github.com/nukata/little-scheme-in-php)               0.2.0 | PHP 7.1.33: `php scm.php`                             |   59.27    |    0.03    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.1.0 | Python 3.7.7: `python3 scm.py`                        |   83.71    |    0.02    |
| [little-scheme-in-ruby](https://github.com/nukata/little-scheme-in-ruby)             0.2.1 | Ruby 2.3.7: `ruby scm.rb`                             |   85.95    |    0.02    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.1.0 | Python 2.7.16: `python scm.py`                        |   92.02    |    0.02    |


<a name="tower"></a>
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
;; A meta-circular little Scheme v1.2 R02.03.25 by SUZUKI Hisao
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

real	0m0.006s
user	0m0.003s
sys	0m0.003s
$ time little-scheme-in-go scm.scm < example/fib90.scm
2880067194370816120

real	0m0.042s
user	0m0.038s
sys	0m0.007s
$ time little-scheme-in-go tower/scm-scm.scm < examples/fib90.scm
2880067194370816120

real	0m7.679s
user	0m8.750s
sys	0m0.288s
$ time little-scheme-in-go tower/scm-scm-scm.scm < examples/fib90.scm
2880067194370816120

real	41m2.781s
user	57m51.862s
sys	1m50.150s
$ 
```


<a name="performanceOnTower"></a>
## Performance on the tower

The following table shows the times to run [`tower/scm-scm.scm`](tower/scm-scm.scm) `<` [`examples/nqueens.scm`](examples/nqueens.scm) on each Schemes.
I used the same MacBook Pro as above.

| Scheme                                                                                     | Compiled/Executed on                                  | Time [sec] | Rel. Speed |
|:-------------------------------------------------------------------------------------------|:------------------------------------------------------|-----------:|-----------:| 
| GNU Guile                                                                            2.2.7 | `guile`                                               |    28.38   |   22.2     |
| [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)             1.0.0 | AdoptOpenJDK jdk-11.0.6+10: `make`                    |   532.64   |    1.19    |
| [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)                 1.1.1 | Go 1.14: `go build`                                   |   631.35   |    1.00    |
| [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)       0.1.0 | Crystal 0.33.0: `crystal build --release scm.cr`      |   664.93   |    0.95    |
| [little-scheme-in-lisp](https://github.com/nukata/little-scheme-in-lispl)            0.3.0 | SBCL 2.0.2: `sbcl --script scm.l`                     |   715.89   |    0.88    |
| [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)                 1.0.2 | .NET Core 3.1.2: `dotnet build -c Release`            |  1308.03   |    0.48    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.1.0 | PyPy 7.3.0 (Python 2.7.13): `pypy scm.py`             |  1360.67   |    0.46    |
| [little-scheme-in-typescript](https://github.com/nukata/little-scheme-in-typescript) 1.1.1 | TypeScript 3.8.3/Node.js 13.11.0: `tsc -t ESNext ...` |  2953.61   |    0.21    |
| [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)             0.3.0 | Dart 2.7.1: `dart scm.dart`                           |  3786.97   |    0.17    |
| [little-scheme-in-php](https://github.com/nukata/little-scheme-in-php)               0.2.0 | PHP 7.1.33: `php scm.php`                             | 18028.97   |    0.04    |
