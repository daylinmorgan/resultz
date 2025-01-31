# resultz

like [results](https://github.com/arnetheduck/nim-results/tree/master) but with more pizazz.

add to `.nimble`:

```nim
requires "https://github.com/daylinmorgan/resultz"
```

## "pizazz"

```nim
import resultz # also exports vendored `results`

proc failableThing(a: int): Result[int, string] =
  if a > 0: result.ok(a)
  else: result.err "failed for no reason?"

case failableThing(10) =
of Ok(a):
  echo "do something with ident `a`:" & $a
of Err(e):
  echo "do something with error:" & err
```

