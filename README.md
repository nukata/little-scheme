# A Meta-circular Little Scheme

This is a meta-circular interpreter of a subset of Scheme, inspired by
[Zick Standard Lisp](https://github.com/zick/ZickStandardLisp).

It implements the same language as

- [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)
- [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)
- [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)
- [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)
- [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)
- [little-scheme-in-kotlin](https://github.com/nukata/little-scheme-in-kotlin)
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
=> (globals error number? = < * - + apply call/cc symbol? eof-object? read newline display list not 
null? pair? eq? cons cdr car)
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

|                   |                          |                 |
|:------------------|:-------------------------|:----------------|
| (`car` _lst_)     | (`display` _x_)          | (`+` _n1_ _n2_) |
| (`cdr` _lst_)     | (`newline`)              | (`-` _n1_ _n2_) |
| (`cons` _x_ _y_)  | (`read`)                 | (`*` _n1_ _n2_) |
| (`eq?` _x_ _y_)   | (`eof-object?` _x_)      | (`<` _n1_ _n2_) |
| (`pair?` _x_)     | (`symbol?` _x_)          | (`=` _n1_ _n2_) |
| (`null?` _x_)     | (`call/cc` _fun_)        | (`number?` _x_) |
| (`not` _x_)       | (`apply` _fun_ _arg_)    | (`globals`)     |
| (`list` _x_ ...)  | (`error` _reason_ _arg_) |                 |

- `(error` _reason_ _arg_`)` displays `Error:` _reason_`:` _arg_ and
  goes back to the top level.
  It is based on [SRFI-23](https://srfi.schemers.org/srfi-23/srfi-23.html).

- `(globals)` returns a list of keys of the global environment.
  It is not in the standard.

See [`Global-Env`](scm.scm#L50-L81)
in `scm.scm` for the implementation of the procedures
except `call/cc` and `apply`.  
`call/cc` and `apply` are implemented particularly at 
[`apply-fun`](scm.scm#L133-L157) in `scm.scm`.


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
$ guile scm.scm < examples/yin-yang-puzzle.scm | head

*
**
***
****
*****
******
*******
********
*********
$ 
```


<a name="performance"></a>
## Performance

The following table shows the times to run [`scm.scm`](scm.scm) `<` [`examples/nqueens.scm`](examples/nqueens.scm) on each Schemes.
I used MacBook Pro (15-inch, 2016), 2.6GHz Core i7, 16GB 2133MHz LPDDR3, macOS Mojave 10.14.6.

| Scheme                                                                                     | Compiled/Executed on                                  | Time [sec] | Rel. Speed |
|:-------------------------------------------------------------------------------------------|:------------------------------------------------------|-----------:|-----------:|
| GNU Guile                                                                            2.2.7 | `guile`                                               |    0.13    |   14.4     |
| [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)                 1.1.0 | .NET Core 3.1.2: `dotnet build -c Release`            |    1.87    |    1.00    |
| [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)                 1.2.0 | Go 1.14.2: `go build`                                 |    2.00    |    0.94    |
| [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)             1.1.0 | AdoptOpenJDK jdk-11.0.6+10                            |    2.02    |    0.93    |
| [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)       0.2.0 | Crystal 0.34.0: `crystal build --release scm.cr`      |    2.15    |    0.87    |
| [little-scheme-in-lisp](https://github.com/nukata/little-scheme-in-lisp)             0.4.0 | SBCL 2.0.2: `sbcl --script scm.l`                     |    2.38    |    0.79    |
| [little-scheme-in-kotlin](https://github.com/nukata/little-scheme-in-kotlin)         0.2.0 | Kotlin 1.3.71/AdoptOpenJDK jdk-11.0.6+10              |    2.38    |    0.79    |
| [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)                 1.1.0 | Mono 6.8.0: `csc -o -r:System.Numerics.dll *.cs`      |    2.77    |    0.68    |
| [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)             0.4.0 | Dart 2.7.2: `dart scm.dart`                           |    3.71    |    0.50    |
| [little-scheme-in-dart](https://github.com/nukata/little-scheme-in-dart)             0.4.0 | Dart 2.7.2: `dart2native scm.dart`; `./scm.exe`       |    3.72    |    0.50    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.2.0 | PyPy 7.3.0 (Python 2.7.13): `pypy scm.py`             |    4.73    |    0.40    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.2.0 | PyPy 7.3.0 (Python 3.6.9): `pypy3 scm.py`             |    5.19    |    0.36    |
| [little-scheme-in-typescript](https://github.com/nukata/little-scheme-in-typescript) 1.2.1 | TypeScript 3.8.3/Node.js 13.12.0: `tsc -t ESNext ...` |    7.17    |    0.26    |
| [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)       0.2.0 | Crystal 0.34.0: `crystal scm.cr`                      |    9.88    |    0.19    |
| [little-scheme-in-php](https://github.com/nukata/little-scheme-in-php)               0.3.0 | PHP 7.1.33: `php scm.php`                             |   44.84    |    0.04    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.2.0 | Python 3.8.2: `python3 scm.py`                        |   81.72    |    0.02    |
| [little-scheme-in-ruby](https://github.com/nukata/little-scheme-in-ruby)             0.3.0 | Ruby 2.3.7: `ruby scm.rb`                             |   84.80    |    0.02    |
| [little-scheme-in-python](https://github.com/nukata/little-scheme-in-python)         3.2.0 | Python 2.7.16: `python scm.py`                        |   88.78    |    0.02    |


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
;; A meta-circular little Scheme v1.3 R02.04.12 by SUZUKI Hisao
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
=> ($Intrinsic $Closure (x) ((+ (fst x) (snd x))) #<(op):((if (eq? op (quote car)) CAR_ (if (eq? op 
(quote cdr)) CDR_ (if (pair? op) (set! CDR_ (car op)) (_error "unknown op" op))))):#<| CAR_ CDR_ Glo
balEnv>>)
```

Note that the _intrinsic_ function `+` is now implemented by a _closure_
of `scm.scm`, the underlying Scheme here.

You can repeat the above process any times.
Try [`tower/scm-scm-scm.scm`](tower/scm-scm-scm.scm) and you will find it runs
prohibitively _slowly_ as might be expected.

```
$ time ./little-scheme-in-go examples/yin-yang-puzzle.scm | head -4

*
**
***

real	0m0.007s
user	0m0.004s
sys	0m0.005s
$ time ./little-scheme-in-go scm.scm < examples/yin-yang-puzzle.scm | head -4

*
**
***

real	0m0.010s
user	0m0.006s
sys	0m0.005s
$ time ./little-scheme-in-go tower/scm-scm.scm < examples/yin-yang-puzzle.scm | head -4

*
**
***

real	0m0.386s
user	0m0.434s
sys	0m0.026s
$ time ./little-scheme-in-go tower/scm-scm-scm.scm < examples/yin-yang-puzzle.scm | head -4

*
**
***

real	1m46.486s
user	2m33.903s
sys	0m5.011s
$ 
```


<a name="performanceOnTower"></a>
## Performance on the tower

The following table shows the times to run [`tower/scm-scm.scm`](tower/scm-scm.scm) `<` [`examples/nqueens.scm`](examples/nqueens.scm) on each Schemes.
I used the same MacBook Pro as above.

| Scheme                                                                                     | Compiled/Executed on                                  | Time [sec] | Rel. Speed |
|:-------------------------------------------------------------------------------------------|:------------------------------------------------------|-----------:|-----------:|
| GNU Guile                                                                            2.2.7 | `guile`                                               |    27.32   |   18.5     |
| [little-scheme-in-cs](https://github.com/nukata/little-scheme-in-cs)                 1.1.0 | .NET Core 3.1.2: `dotnet build -c Release`            |   506.15   |    1.00    |
| [little-scheme-in-java](https://github.com/nukata/little-scheme-in-java)             1.1.0 | AdoptOpenJDK jdk-11.0.6+10                            |   506.79   |    1.00    |
| [little-scheme-in-kotlin](https://github.com/nukata/little-scheme-in-kotlin)         0.2.0 | Kotlin 1.3.71/AdoptOpenJDK jdk-11.0.6+10              |   598.57   |    0.85    |
| [little-scheme-in-go](https://github.com/nukata/little-scheme-in-go)                 1.2.0 | Go 1.14.2: `go build`                                 |   604.27   |    0.84    |
| [little-scheme-in-crystal](https://github.com/nukata/little-scheme-in-crystal)       0.2.0 | Crystal 0.34.0: `crystal build --release scm.cr`      |   624.52   |    0.81    |
| [little-scheme-in-lisp](https://github.com/nukata/little-scheme-in-lisp)             0.4.0 | SBCL 2.0.2: `sbcl --script scm.l`                     |   676.82   |    0.75    |
