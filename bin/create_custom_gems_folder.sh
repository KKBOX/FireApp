#!/bin/bash
gem install sass -i $1 --no-rdoc --no-ri 
gem install compass -i $1 --no-rdoc --no-ri 
gem install rack-test fssm execjs coffee-script rack tilt activesupport tzinfo i18n rake haml slim kramdown -i $1 --no-rdoc --no-ri 
curl  -o tka-serve.zip --location-trusted https://github.com/tka/serve/zipball/master 
unzip tka-serve.zip
rm tka-serve.zip
mv tka-serve-* $1/gems/serve-1.5.1
cp $1/gems/serve-1.5.1/serve.gemspec $1/specifications
curl  -o tka-rack-coffee.zip --location-trusted https://github.com/tka/rack-coffee/zipball/master
unzip tka-rack-coffee.zip
rm tka-rack-coffee.zip
mv tka-rack-coffee-* $1/gems/rack-coffee-1.0.0
cp $1/gems/rack-coffee-1.0.0/rack-coffee.gemspec $1/specifications
