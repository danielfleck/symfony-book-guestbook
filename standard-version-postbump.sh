#!/usr/bin/env bash
APP_VERSION=`cat $PWD/APP_VERSION`
DATETIME=`date "+%Y-%m-%d %H:%M:%S%z"`
sed -i "s/^> Versão:.*/> Versão: $APP_VERSION/" README.md
sed -i "s/^> Data:.*/> Data: $DATETIME/" README.md
git add README.md
