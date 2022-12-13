#!/bin/bash

year='[0-9][0-9][0-9][0-9]'
date='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'

for yearDir in $year; do

cd $yearDir

rm -rf $year.md || true #remove old file if exists

for file in $(ls -R | grep "\.md$" | grep -v "$year.md" | grep -v "\toc") ; do #append blank line to eof of every file date markdown file, but only if a newline doesn't already exist

if [ "$(tail -c1 $date/$file; echo x)" != $'\nx' ]; then
    echo "" >>$date/$file
fi
done

for file in $(ls -R | grep "\.md$" | grep -v "$year.md" | grep -v "\toc" | tac) ; do cat $date/$file ; echo ; done >> $yearDir.md #assemble all `YYYY-MM-DD` files in a `YYYY-MM-DD` directory into `YYYY.md`

tocArchive="toc"
tocTitles="$tocArchive/tocTitles.txt"
tocLinks="$tocArchive/tocLinks.txt"
toc="$tocArchive/tocFinal.txt"

mkdir -p $tocArchive #create table of contents directory if one doesn't exist

rm -rf $tocTitles || true #remove existing files without throwing errors if they don't exist
rm -rf $tocLinks || true
rm -rf $toc || true

for file in $(ls -R | grep "\.md$" | grep -v "$year.md" | grep -v "\toc" | tac ); do #get all `YYYY.md/YYYY-MM-DD` files in reverse chronological order

cat $date/$file | while read line #pull every line that starts with `#` (i.e., a heading) into a `.txt file in reverse chronological order
do
[[ "$line" =~ '# ' ]] && echo $line >> $tocTitles
done

done

sed -i '/## /d' $tocTitles #title file: remove any 4th-, 5th-, or 6th-level headings copied
sed -i '/### /d' $tocTitles
sed -i '/#### /d' $tocTitles
sed -i '/##### /d' $tocTitles
sed -i '/###### /d' $tocTitles
sed -i '/Fixed bugs/d' $tocTitles

sed -i 's|# ||g' $tocTitles #title file: remove pound signs
sed -e 's| |-|g' < $tocTitles > $tocLinks #title file > link file: add dashes in between each word and save to another file for links
sed -i 's|^|- [|g' $tocTitles #title file: add bullets before titles and brackets around titles
sed -i 's|$|]|g' $tocTitles
sed -i 's|.|\L&|g' $tocLinks #link file: make lowercase and add parentheses around
sed -i 's|^|(#|g' $tocLinks
sed -i 's|$|)|g' $tocLinks

paste $tocTitles $tocLinks > $toc #merge title file and link file
sed -E -i 's|\t||g' $toc #remove tabs
echo "" >> $toc #newline at eof

prependToc=`cat $toc $year.md`; echo "$prependToc" > $year.md #put the table of contents at the top of `YYYY.md``
sed -E -i '1s/^/Scroll up slightly after the jump.\n\n/' $year.md #put this text at the top of `YYYY.md` (above the table of contents placed there above)
sed -E -i "1s/^/\*\*Releases during $yearDir\*\*\n\n/" $year.md #put this text at the top of `YYYY.md` (above the `scroll up...` text placed there above)

perl -i -0pe 's/# (\d{1,2}) ([A-Za-z]+) (\d{4})/# <a id=\"\1-\2-\3\"><\/a>\1 \2 \3/g' $year.md #due to verint constraints, modify markdown of first line of each `.md` file (the date) to include an html link
perl -i -0pe 's/# (\d{1,2}) ([A-Za-z]+) (\d{4})/# <a id=\"\1-\2-\3\"><\/a>\1 \2 \3/g' $year.md
sed -E -i '/# <a id=/s/-[A-Z][a-z]+-/\L&/g' $year.md

echo "" >> $year.md #newline at eof

cd ..

done