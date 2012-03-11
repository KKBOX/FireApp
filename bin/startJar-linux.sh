#!/bin/sh
if [ "$1" = "full" ]; then
  rake rawr:clean
fi 
rake rawr:jar

#"-Djruby.compat.version=1.9" \
java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -Djruby.reify.classes=true  \
-Xms512m -Xmn256m \
-client -Xverify:none  -Xbootclasspath/a:lib/java/jruby-complete.jar -jar package/jar/fire-app.jar $1
