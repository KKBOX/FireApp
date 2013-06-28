![Fire.app](https://github.com/handlino/FireApp/raw/master/lib/images/icon/256.png)

# Fire.app

[Fire.app][fireapp] is a **menubar only app** for dead easy HTML prototyping.

This fork by [Aaron](http://aaron.md/) adds the ability to minify files on save rather than build.

Fire.app is written in **Java (JRuby)**, and works in mac, linux and pc.

# Notes on this version:

## Features and Changes

1. Can use configuration options to set minified folder name.

1. Can be enabled and disabled in project options panel. 
	* *Minify On Clean & Compile*: defaults to true;
	* *Minify On Save*: defaults to false;

1. Watches all .js files in _javascripts\_dir_ folder recursively for changes and saves the uglified versions as filename.min.js to the folder _javascripts\_min\_dir_. 

1. Works with Clean & Compile (If you disable minify\_on\_clean, it will delete the minified folder and not recreate it.)

1. Works with both LiveReload and coffeescript generated files.

1. Handles deleting .min.js files when .js files are deleted.

1. If you manually save a .min.js in your main js directory, it will create a minified version of it in your js-min folder, but will not change the extension to ".min.min.js".


**Your JS folder and your JS min folder can be at different levels**  so you can set up a directory structure like:

```
/main folder
	/assets
		/js-min
		/css
		/images
	/library
		/coffee
		/js
		/scss
```

## Issues:

1. If your main /js/ folder contains "jquery.min.js" and "jquery.js" and you delete "jquery.min.js" it will also delete "/js-min/jquery.min.js".  (Rare case when migrating to using minify, a manual clean and compile should be used instead)

## Questions

1. If in your source js folder you have a .min.js, should it be directly copied to js_min folder instead of minified again with the same name?

# System Requirement

Fire.app has been tested in:

* Windows: Windows 7/Vista/XP
* OS X: 10.5, 10.6 32/64bit, 10.7 32/64bit
* Linux: Arch Linux 32/64bit

Fire.app is written in **Java (JRuby)**, so you must install JRE(Java Runtime Environment) first. If you do not have JRE installed, Fire.app will guide you to install it first.

## Download

You can buy Fire.app from [our official site][fireapp]. Once you bought it, We will send an email with download links to your PayPal's email address. You will also get 1.x updates for free.

Fire.app is **GPLv2 licensed** because we love open source so much. The source code is [available on GitHub][fireapp-github]. You can build it your own, or even modify it based on your needs.

## Install

There is no need to **install** Fire.app. You can just unzip and put it anywhere. You can even use Dropbox to sync between computers.

## Build Your Own

If you want to build your own copy, you will need [JRuby](http://jruby.org/) and [rawr](http://rawr.rubyforge.org/).

## License

Copyright (c) 2012 Handlino Inc.
Licensed under GPL v2.

[fireapp]: http://fireapp.handlino.com/
[fireapp-github]: http://github.com/handlino/fireapp