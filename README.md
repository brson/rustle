One-line installation of Cargo applications.

Need to show your friends that Rust application you made, but your
friends don't Rust? That's when you need to rustle.

If your Cargo package produces static binaries then this script can
install it in one line. It downloads the Rust nightly, builds your
application, then packages and installs it.

Install a Cargo package:

    $ curl -sf https://raw.githubusercontent.com/brson/rustle/master/rustle.sh | sh -s -- https://github.com/ogham/exa
    $ exa

Then to uninstall:

    $ sudo /usr/local/lib/rustle/uninstall.sh --components=exa

or more compactly:

    $ sudo /usr/local/lib/rustle/uninstall.sh

which will uninstall everything installed by rustle.

If the project doesn't build on the current nightly, then it's
possible to specify other revisions with the `--toolchain` flag,
which accepts the formats as [multirust].

    $ curl -sf https://raw.githubusercontent.com/brson/rustle/master/rustle.sh | sh -s -- https://github.com/gchp/iota --toolchain nightly-2015-02-19
    $ iota

[multirust]: https://github.com/brson/multirust

# Projects that are likely compatible

* `https://github.com/gchp/iota`. A text editor.
* `https://github.com/ogham/exa`. An improvement on ls.

# Tips

If you already have multirust installed then you can avoid downloading
the nightly by setting `MULTIRUST_HOME=~/.multirust`.
