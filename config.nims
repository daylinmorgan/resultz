import std/os except getCurrentDir
import std/[strutils, strformat]

task vendor, "update vendored deps":
  const baseUrl = "https://raw.githubusercontent.com/arnetheduck/nim-results/refs/heads/master/"
  withDir "src/vendor":
    for f in ["results.nim", "LICENSE-MIT"]:
      exec "wget -O $1 $2$1" % [f, baseUrl]

proc docFixup(deployDir:string, pkgName: string) =
  ## apply renames to api docs
  withDir deployDir:
    mvFile(pkgName & ".html", "index.html")
    for file in walkDirRec(".", {pcFile}):
      # As we renamed the file, we need to rename that in hyperlinks
      exec(r"sed -i -r 's|$1\.html|index.html|g' $2" % [pkgName, file])
      # drop 'src/' from titles
      exec(r"sed -i -r 's/<(.*)>src\//<\1>/' $1" % file)

task docs, "Deploy doc html + search index to public/ directory":
  let
    deployDir = getCurrentDir() / "public"
    pkgName = "resultz"
    gitFlags = fmt"--git.url:'https://github.com/daylinmorgan/{pkgName}' --git.commit:main --git.devel:main"
    docCmd = fmt"doc {gitFlags} --index:on --outdir:{deployDir}"
  when defined(clean):
    echo fmt"clearing {deployDir}"
    rmDir deployDir
  # for module in ["cligen", "chooser", "logging", "hwylcli", "parseopt3"]:
    # selfExec fmt"{docCmd} --docRoot:{getCurrentDir()}/src/ src/hwylterm/{module}"
  selfExec fmt"{docCmd} --project  --project src/{pkgName}.nim"
  docFixup(deployDir, pkgName)
