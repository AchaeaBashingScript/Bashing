#!/bin/sh
VERSION=$(printf "%s-pre%s" `cat .version` `date -I`)
echo "Making version" $VERSION
API_STRING='{"tag_name": "v%s","target_commitish": "master","name": '\
'"v%s","body": "Release of version %s","draft": false,"prerelease": true}'
API_JSON=$(printf "$API_STRING" "$VERSION" "$VERSION" "$VERSION")
echo $API_JSON
#curl --data $API_JSON \
#https://api.github.com/repos/keneanung/Bashing/releases?access_token=:access_token \
#-o output.txt
zip Bashing.mpackage config.lua script.lua Bashing.xml
out=$?
if [ $out -ne 0 ]
then
  echo "Zip failed:" "$out"
  exit 1
fi
assets=`cat output.txt | jq ".assets_url" | egrep -o '[^"]+'`
out=$?
if [ $out -ne 0 ]
then
  echo "Grep failed:" "$out"
  exit 1
fi
echo $assets
