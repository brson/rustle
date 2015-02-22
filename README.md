# One-line installation of Cargo applications

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

# Projects that are likely compatible

* `https://github.com/gchp/iota`. A text editor.
* `https://github.com/ogham/exa`. An improvement on ls.

# Tips

If you already have multirust installed then you can avoid downloading
the nightly by setting `MULTIRUST_HOME=~/.multirust`.
