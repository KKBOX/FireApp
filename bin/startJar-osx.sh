#!/bin/sh
bundle exec rake rawr:clean
bundle exec rake rawr:bundle:write_version_info
bundle exec rake rawr:jar
#java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails \
#  -Xms128m  -Xmn32m -Xmx128m \
java  -Dfile.encoding=utf8 -d64 -client -Xverify:none -XstartOnFirstThread -Xbootclasspath/a:lib/java/jruby-complete.jar -jar package/jar/fire-app.jar $@
