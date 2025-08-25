import unittest

import resultz

suite "helper templates":
  test "exceptions as strings":
    proc raisingProc(): int =
      raise newException(IOError, "This is IO speaking, Er Yes you can!")

    let r = catchMsg: raisingProc()
    check r == Result[int, string].err("IOError: This is IO speaking, Er Yes you can!")

proc f(ok: bool): Result[string, string] =
  if ok:
    result.ok "worked!"
  else:
    result.err "failed!"

proc f2(ok: bool): Opt[string] =
  if ok:
    result.ok "worked!"

proc f3(ok: bool): Result[void, string] =
  if ok: ok()
  else: err "failed!"

suite "caseStmt":
  test "ok/err":
    case f(true):
    of Ok(msg):
      check msg == "worked!"
    of Err(e): discard

    case f(false):
    of Ok(msg): discard
    of Err(e):
      check e == "failed!"

    case f3(false):
    of Ok(): discard
    of Err(e):
      check e == "failed!"

  test "some/none":
    case f2(true):
    of Some(msg):
      check msg == "worked!"
    of None(): discard

    case f2(false):
    of Some(_): discard
    of None():
      check true

  test "type alias/generics":
    type R[T] = Result[T, string]
    proc f3(ok: bool): R[string] =
      if ok: ok "worked!"
      else: err "failed!"

    case f3(true):
    of Ok(v): check v == "worked!"
    of Err(e): discard

