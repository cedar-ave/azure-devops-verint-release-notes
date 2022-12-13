#! /bin/bash

verintToken=""
communityUrl="" #example: docs.mysite.com
wikiId="" #example: 123
year='[0-9][0-9][0-9][0-9]'

for yearDir in $year; do

cd $yearDir

for filename in $year.md ; do

yearName="${filename%.*}" #trims filename extension off
fileHtml="$yearName.html" #html extension on file

if [ $yearName = 2023 ]; then pageId=1234 ; fi
if [ $yearName = 2024 ]; then pageId=5678 ; fi

pandoc -f markdown -t html $filename -o $fileHtml #transform markdown to html

sed -i 's|align="left"||g' $fileHtml
sed -i 's|<col style="width.*?>||g' $fileHtml
sed -i 's| class=".*?"||g' $fileHtml
sed -i 's|<span style="font-weight:bold;">(.*?)</span>|<b>$1</b>|g' $fileHtml
perl -i -0pe 's/<figure.*?>//g' $fileHtml
perl -i -0pe 's/<\/figure>//g' $fileHtml
perl -i -0pe 's/<figcaption.*?>.*?<\/figcaption>//g' $fileHtml

perl -i -0pe 's/ id="\w+-\d{4}"//g' $fileHtml #force anchor links to include day (verint applies only month-year, which doesn't support 2+ release dates in a month)
perl -i -0pe 's/ id="\w+-\d{4}-\d"//g' $fileHtml
perl -i -0pe 's/ id="\w+_\d{4}"//g' $fileHtml
perl -i -0pe 's/ id="\w+_\d{4}-\d"//g' $fileHtml

juice --css ../style.css $fileHtml $fileHtml #apply custom css

curl -v -H "Rest-User-Token: $verintToken" -H "Rest-Method: PUT" -F "Body=<$fileHtml" POST https://$communityUrl/api.ashx/v2/wikis/$wikiId/pages/$pageId.json #send to verint community

done

done