import std/strformat

task vendor, "update vendored deps":
  const baseUrl = "https://raw.githubusercontent.com/arnetheduck/nim-results/refs/heads/master/"
  withDir "src/vendor":
    for f in ["results.nim", "LICENSE-MIT"]:
      exec fmt"wget -O {f} {baseUrl}{f}"
