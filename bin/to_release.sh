#!/bin/bash 
cp packages/fire.app.windows* packages/fire.app.windows.$1.zip
cp packages/fire.app.osx* packages/fire.app.osx.$1.zip
cp packages/fire.app.linux* packages/fire.app.linux.$1.zip
ls -lot packages
