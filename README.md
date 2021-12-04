# goenv download

An alternative for https://github.com/syndbg/goenv/tree/master/plugins/go-build

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
1.16.6
1.16.5
1.16.4
1.16.3
1.16.2
1.16.1
1.16
1.15.15
1.15.14
1.15.13
1.15.12

❯ goenv download latest
Downloading https://dl.google.com/go/go1.17.4.darwin-amd64.tar.gz
Unpacking /Users/skaji/src/github.com/skaji/goenv-download/cache/go1.17.4.darwin-amd64.tar.gz
Successfully installed /Users/skaji/.goenv/versions/1.17.4
```

# Author

Shoichi Kaji

# License

Apache 2.0
