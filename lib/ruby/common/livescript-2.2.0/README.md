Ruby LiveScript
=================

Ruby LiveScript is a bridge to the official LiveScript compiler.

    LiveScript.compile File.read("script.ls)

This gem is a fork of `ruby-coffee-script` adapted for LiveScript.

Installation
------------

    gem install livescript


Dependencies
------------

This library depends on the `livescript-source` gem which is
updated any time a new version of LiveScript is released. (The
`livescript-source` gem's version number is synced with each
official LiveScript release.) This way you can build against
different versions of LiveScript by requiring the correct version of
the `livescript-source` gem.

In addition, you can use this library with unreleased versions of
LiveScript by setting the `LIVESCRIPT_SOURCE_PATH` environment
variable:

    export LIVESCRIPT_SOURCE_PATH=/path/to/LiveScript/extras/livescript.js

### JSON

The `json` library is also required but is not explicitly stated as a
gem dependency. If you're on Ruby 1.8 you'll need to install the
`json` or `json_pure` gem. On Ruby 1.9, `json` is included in the
standard library.

### ExecJS

The [ExecJS](https://github.com/sstephenson/execjs) library is used to automatically choose the best JavaScript engine for your platform. Check out its [README](https://github.com/sstephenson/execjs/blob/master/README.md) for a complete list of supported engines.
