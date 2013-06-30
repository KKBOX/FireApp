#!/bin/sh
bundle exec rake rawr:clean
bundle exec rake rawr:bundle:write_version_info
bundle exec rake rawr:jar

#"-Djruby.compat.version=1.9" \
#java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -Djruby.reify.classes=true  \
#java -XX:-UseParallelOldGC -XX:NewRatio=4  -Xmx384m -Xms128m -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails  \
#java -XX:+PrintGCTimeStamps -XX:+PrintGCDetails  \
java -XX:-UseParallelOldGC -XX:NewRatio=4  -Xmx384m -Xms128m -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails  \
-client -Xverify:none  -Xbootclasspath/a:lib/java/jruby-complete.jar -jar package/jar/fire-app.jar $@
