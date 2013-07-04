
# CommonJS [![Build Status](https://secure.travis-ci.org/cowboyd/commonjs.rb.png)](http://travis-ci.org/cowboyd/commonjs.rb)

Host CommonJS JavaScript environments in Ruby

## Why?

The internet is now awash with non-browser JavaScript code. Much of this code conforms to some
simple conventions that let you use it anywhere you have a JavaScript interpreter available. These
conventions are collectively called "commonjs"

We have several JavaScript interpreters available to us from Ruby. Therefore, why shouldn't we be
able to use commonjs applications and libraries?

## Using common JS from Ruby.

`CommonJS` now passes all of the Modules 1.0 unit tests

    env = CommonJS::Environment.new(:path => '/path/to/lib/dir')
    env.require('foo.js')



## Future directions

By default, all you get with a bare commonjs environment is the Modules API

The plan however, is to allow you to extend your commonjs environment to have whatever native
interfaces you want in it. So for example, if you want to allow filesystem access, as well as
access to the process information, you would say:

    env.modules :filesystem, :process

## Supported runtimes

### Current

* The Ruby Racer (V8) - [https://github.com/cowboyd/therubyracer]
* The Ruby Rhino (JRuby) - [https://github.com/cowboyd/therubyrhino]

### Desired

* Johnson (TraceMonkey) - [https://github.com/jbarnette/johnson]
* Lyndon (MacRuby) - [https://github.com/defunkt/lyndon]
