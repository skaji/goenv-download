# goenv download

An alternative to https://github.com/syndbg/goenv/tree/master/plugins/go-build

While go-build keeps *definitions* in its `share/` directory statically,
goenv download gets them from https://go.googlesource.com/go/+refs/tags?format=TEXT dynamically.

# Install

```
git clone https://github.com/skaji/goenv-download $(goenv root)/plugins/goenv-download
```

# Usage

```
❯ goenv download -l
1.17.4
1.17.3
1.17.2
1.17.1
1.17
1.16.11
1.16.10
1.16.9
1.16.8
1.16.7

❯ goenv download latest
Downloading https://dl.google.com/go/go1.16.11.darwin-amd64.tar.gz
Unpacking /Users/skaji/env/goenv/plugins/goenv-download/cache/go1.16.11.darwin-amd64.tar.gz
Successfully installed /Users/skaji/env/goenv/versions/1.16.11
```

# Author

Shoichi Kaji

# License

Apache 2.0
