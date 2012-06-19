#!/bin/sh
rake rawr:clean
rake rawr:jar

#"-Djruby.compat.version=1.9" \
#java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -Djruby.reify.classes=true  \
java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails  \
-client -Xverify:none  -Xbootclasspath/a:lib/java/jruby-complete.jar -jar package/jar/fire-app.jar $1
