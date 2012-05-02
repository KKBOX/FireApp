# Build for OSX Lion

## Prerequisites

You will need [JRuby](http://jruby.org/) and [rawr](http://rawr.rubyforge.org/).

### JRuby

For example, installing jRuby 1.6.7 with [rvm](https://rvm.io):

    echo "rvm use jruby-1.6.7@fireapp --create --install" > .rvmrc;
    # rvm will try to install jRuby now
    cd .

    # Verify it
    ruby --version;

or [rbenv](https://github.com/sstephenson/rbenv):

    echo "jruby-1.6.7" > .rbenv-version;
    rbenv-install jruby-1.6.7;
    ruby --version;

### rawr

Install rawr gem using [bundler](http://gembundler.com):

    gem install bundler;
    bundle install;

## Build it

    # Available tasks:
    rake -T;

    # Compile it, generate th FireApp.app:
    rake rawr:compile;
    rake rawr:bundle:app;

    # Drag to Applications folder.
    open package/
