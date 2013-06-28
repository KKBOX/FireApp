![Fire.app](https://github.com/handlino/FireApp/raw/master/lib/images/icon/256.png)

# Fire.app

[Fire.app][fireapp] is a **menubar only app** for dead easy HTML prototyping.

This fork by [Aaron](http://aaron.md/) adds the ability to minify files on save rather than build.

Fire.app is written in **Java (JRuby)**, and works in mac, linux and pc.

# Notes on this version:

This is a hackjob that works. This is my first project ever in ruby that involved doing anything other changing a line or two of code. I don't expect a straight pull into the main project, but it may be useful for others.

Features:

1. Watches all .js files in javascripts_dir folder recursively for changes and saves the uglified versions as filename.min.js to the folder "#{javascripts_dir}-min". 

2. Works with both LiveReload and coffeescript generated files.

3. Automatically uglifies all .js files on project load (except files named .min.js already)

4. Handles deleting .min.js files when .js files are deleted.

5. If you manually save a .min.js in your main js directory, it will create a minified version of it in your js-min folder, but will not change the extension to ".min.min.js".

6. Can set configuration options to set minified folder names.

7. Works with Clean & Compile

Issues:

1. If your main /js/ folder contains "jquery.min.js" and "jquery.js" and you delete "jquery.min.js" it will also delete "/js-min/jquery.min.js"

2. Renaming a file will delete the old .min.js but not create a new file

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