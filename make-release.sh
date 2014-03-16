#!/usr/bin/env sh
if `echo "$TRAVIS_BRANCH" | egrep -q "^v\d+\.\d+"`
then
  echo "Abort creating release for release tag."
  exit 0
fi
VERSION=$(printf "%s-pre%s(%s)" `cat .version` "$TRAVIS_COMMIT" "$TRAVIS_BRANCH")
echo "Making version" $VERSION
echo "return '$VERSION'" > version.lua 

API_STRING='{"tag_name": "v%s","target_commitish": "master","name": '\
'"v%s","body": "Release of version %s","draft": false,"prerelease": true}'
API_JSON=$(printf "$API_STRING" "$VERSION" "$VERSION" "$VERSION")

API_URL=$(printf \
"https://api.github.com/repos/keneanung/Bashing/releases?access_token=%s" \
"$ACCESS_TOKEN")

http_code=`curl -s -w "%{http_code}" --data "$API_JSON" -o output.txt "$API_URL"` 
out=$?
http_code=201
if [ $out -ne 0 ]
then
  echo "Ceating release failed:" "$out"
  exit 1
fi
if [ "$http_code" != "201" ]
then
  echo "Ceating release failed:" "$http_code"
  exit 1
fi

zip Bashing.mpackage config.lua script.lua Bashing.xml version.lua
out=$?
if [ $out -ne 0 ]
then
  echo "Zip failed:" "$out"
  exit 1
fi

UPLOADS_URL=`cat output.txt | jq ".upload_url" | egrep -o '[^"]+'`
out=$?
if [ $out -ne 0 ]
then
  echo "Grep failed:" "$out"
  exit 1
fi
UPLOADS_URL=`echo "$UPLOADS_URL" | sed 's/{//' | sed 's/}//'`
UPLOADS_URL=`echo "$UPLOADS_URL""=%s&access_token=%s"`
UPLOADS_URL=$(printf "$UPLOADS_URL" "Bashing.mpackage" "$ACCESS_TOKEN")

http_code=`curl -s -w "%{http_code}" \
--data-binary "@Bashing.mpackage" -H "Content-Type: application/octet-stream" \
-o output.txt "$UPLOADS_URL"`
out=$?
if [ $out -ne 0 ]
then
  echo "Ceating asset failed:" "$out"
  exit 1
fi
if [ "$http_code" != "201" ]
then
  echo "Ceating asset failed:" "$http_code"
  exit 1
fi
