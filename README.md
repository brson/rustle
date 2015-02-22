**DO NOT USE THIS YET. IT DOES NOT WORK AND WILL DESTROY EVERYTHING YOU LOVE**

Install a Cargo package 

    $ curl -sf https://raw.githubusercontent.com/brson/rustle/master/rustle.sh | sh -s -- https://github.com/gchp/iota
    $ iota

or

    $ curl -sf https://raw.githubusercontent.com/brson/rustle/master/rustle.sh | sh -s -- https://github.com/ogham/exa
    # exa

Then to uninstall:

    $ sudo /usr/local/lib/rustle/uninstall.sh --components=iota,exa

or more compactly:

    $ sudo /usr/local/lib/rustle/uninstall.sh

which will uninstall everything installed by rustle.

# Tips

If you already have multirust installed then you can avoid downloading
the nightly by setting `MULTIRUST_HOME=~/.multirust`.
