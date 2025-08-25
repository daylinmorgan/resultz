import std/[macros, strutils, strformat]
import ./vendor/results
export results

template exceptErr*(m: string) =
  return err(m & "\n" & getCurrentException().msg)

template catchMsg*(body: typed): Result[type(body), string] =
  ## Catch exceptions for body and store them in the Result
  ##
  ## ```
  ## let r = catch: someFuncThatMayRaise()
  ## ```
  type R = Result[type(body), string]

  try:
    when type(body) is void:
      body
      R.ok()
    else:
      R.ok(body)
  except CatchableError as eResultPrivate:
    R.err($eResultPrivate.name &  ": " & eResultPrivate.msg)

template bailMsg*(m: string, body: untyped) =
  ## wrapper for try except to swallow compiler error and return with err(m)
  try:
    body
  except:
    exceptErr m

type
  Branch = enum
    Ok, Some, Err, None

func branchKind(n: NimNode): Branch =
  expectKind n, { nnkCall, nnkCommand, nnkIdent}
  case n.kind
  of nnkCall:
    result = parseEnum[Branch]($n[0])
  of nnkCommand:
    result = parseEnum[Branch]($n[0])
  of nnkIdent:
    result = parseEnum[Branch]($n)
  else: assert false

func nimNodeFromResultBranch(branch: NimNode): NimNode =
  if branch.len == 0:
    ident"void"
  else:
    branch[0][1]

func getTypeNodes(resultNode: NimNode): tuple[T: NimNode, E: NimNode] =
  ## given a NimNode of type `Result*[T, E] = object` extract T and E as nodes
  let resultImpl = getTypeImpl(resultNode)
  let eTypeBranch = resultImpl[2][0][1][1]
  let vTypeBranch = resultImpl[2][0][2][1]
  result.E = nimNodeFromResultBranch(eTypeBranch)
  result.T = nimNodeFromResultBranch(vTypeBranch)


macro `case`*(n: Result): untyped =
  result = newStmtList()

  var (T, E) = getTypeNodes(n[0])
  let isOpt = E == ident"void"

  let
    tmp = genSym(nskLet)
    getSym = bindSym"get"
    errorSym = bindSym"error"

  result.add newLetStmt(tmp, n[0])

  template checkIdent =
    if it[0].len != 2:
        error fmt"expected ident for {bk} branch. to ignore value use `_`"

  var okBranch, errBranch = newTree(nnkStmtList)
  for i in 1 ..< n.len:
    let it = n[i]

    case it.kind
    # TODO: simplify and abstract
    of nnkOfBranch:
      let bk = it[0].branchKind

      case bk:
      of Ok, Some:
        if bk == Some and T.typeKind == ntyVoid:
          error "Some should be used with Opt[T isnot void]/Result[T isnot void, E]"

        elif T.typeKind notin {ntyVoid, ntyNone}:
          checkIdent()

          let okIdent = it[0][1]
          if $okIdent != "_":
            okBranch.add quote do:
              let `okIdent` = `getSym`(`tmp`)

        okBranch.add it[1]

      of None, Err:
        if bk == None and E.typekind notin {ntyVoid, ntyNone}:
          error "None should be used with Opt[T isnot void]/Result[T isnot void, void]"

        elif bk == Err and E.typeKind != ntyVoid:
          checkIdent()
          let errIdent = it[0][1]
          if $errIdent != "_":
            errBranch.add quote do:
              let `errIdent` = `errorSym`(`tmp`)
          else:
            if it[0].len > 1:
              error fmt"unexpected ident: {it[0][1]} for {bk} branch"

        errBranch.add it[1]

    of nnkElse, nnkElifBranch, nnkElifExpr, nnkElseExpr:
      error "else branch not supported, expected Ok()/Err() or Some()/None()", it
    else:
      error "custom 'case' for Result cannot handle this node", it

  if okBranch.len == 0:
      error (if isOpt: "Some" else: "Ok") & "() case not handled"
  if errBranch.len == 0:
      error (if isOpt: "None" else: "Err") & "() case not handled"

  result.add quote do:
    if `tmp`.isOk:
      `okBranch`
    else:
      `errBranch`

  result = quote do:
    block:
      `result`

{.push raises:[].}

