#!/bin/sh
bundle exec rake rawr:clean
bundle exec rake rawr:bundle:write_version_info
bundle exec rake rawr:jar

#"-Djruby.compat.version=1.9" \
#java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -Djruby.reify.classes=true  \
java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails  \
-client -Xverify:none  -Xbootclasspath/a:lib/java/jruby-complete.jar -jar package/jar/fire-app.jar $@
