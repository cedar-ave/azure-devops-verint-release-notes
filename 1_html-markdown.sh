#!/bin/bash

year='[0-9][0-9][0-9][0-9]'
date='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'

for yearDir in $year; do

if [ -f "$yearDir/$yearDir.html" ] ; then #removes `YYYY.html` in $yearDir if exists
    rm "$yearDir/$yearDir.html"
fi

cd $yearDir

for filename in *.html ; do

if [ -f $filename ]; then
date="${filename%.*}" #trims filename extension off

if [ ! -d $date ]; then #makes a `YYYY-MM-DD` directory if it doesn't exist
mkdir -p $date
fi

mv $date.html $date #moves the `YYYY-MM-DD` file into the matching `YYYY-MM-DD` directory

cd $date

for filename in *.html ; do

fileMd="$date.md" #puts a `.md` extension on file

sed -i -E 's|&lt;span style=&quot;color.*?&gt;||g' $filename #removes random problems (removing all `<span>`s would remove bolds)
sed -i -E 's|&lt;br&gt;| |g' $filename
perl -i -0pe 's/<pre.*?>//g' $filename #removes `<pre>` and `</pre>` but not the contents inside, which include `<code>`
perl -i -0pe 's/<\/pre>//g' $filename
perl -i -0pe 's/(<code.*?>)(<div.*?>)/$2$1/g' $filename #flips `<div>` inside `<code>`
perl -i -0pe 's/(<\/div>)(<\/code>)/$2$1/g' $filename

pandoc -f html -t markdown_strict-native_divs-native_spans-raw_html-bracketed_spans+link_attributes --markdown-headings=atx --columns=110 $filename -o $fileMd #transforms to markdown

sed -E -i 's|&lt;\/div&gt;||g' $fileMd #cleans up markdown
sed -E -i 's|&lt;div&gt;||g' $fileMd
sed -E -i 's|&lt;div>||g' $fileMd
sed -E -i 's|&lt;\/div>||g' $fileMd
sed -E -i 's|&quot;|"|g' $fileMd
sed -E -i 's|&nbsp;| |g' $fileMd
sed -E -i 's|&lt;b&gt;|\*\*|g' $fileMd #bold
sed -E -i 's|&lt;\/b&gt;|\*\* |g' $fileMd
sed -E -i 's|&lt;span.*?&gt;||g' $fileMd
sed -E -i 's|&lt;\/span&gt;||g' $fileMd

perl -i -0pe 's/\n\n\(\\\[(.*?)\\\]/ ([$1]/g' $fileMd #improves work item rendering
perl -i -0pe 's/\\_workitems/_workitems/g' $fileMd

# Create TOC
contentsArchive="toc"
contentsTitle="$contentsArchive/titles.txt"
contentsLink="$contentsArchive/links.txt"
contents="$contentsArchive/final.txt"

mkdir -p $contentsArchive #creates toc directory if doesn't exist

rm -rf $contentsTitle || true #removes existing files without throwing errors if they don't exist
rm -rf $contentsLink || true
rm -rf $contents || true

cat $fileMd | while read line #copies 3rd-level markdown headings into file
do
[[ "$line" =~ '### ' ]] || [[ "$line" =~ '## Fixed bugs' ]] && echo $line >> $contentsTitle
done

sed -i '/#### /d' $contentsTitle #title file | removes any 4th-, 5th-, or 6th-level headings copied
sed -i '/##### /d' $contentsTitle
sed -i '/###### /d' $contentsTitle
sed -i 's|## Fixed bugs|Fixed bugs|g' $contentsTitle #remove pound signs
sed -i 's|### ||g' $contentsTitle

sed -e 's| |-|g' < $contentsTitle > $contentsLink #title file > link file | adds dashes in between each word and saves to another file for links

sed -i 's|^|- [|g' $contentsTitle #title file | adds bullets before titles and brackets around titles
sed -i 's|$|]|g' $contentsTitle

sed -i 's|.|\L&|g' $contentsLink #link file | lowercases and adds parentheses
sed -i 's|^|(#|g' $contentsLink
sed -i 's|$|)|g' $contentsLink

paste $contentsTitle $contentsLink > $contents #title file and link file | merges files
sed -E -i 's|\t||g' $contents

sed -i "s|\[Fixed bugs\](#fixed-bugs)|\[Fixed bugs\](#fixed-bugs_${date})|g" $contents #appends date to `fixed-bugs` anchors to prevent multiple identical anchors on a page
sed -i "s|## Fixed bugs|## <a id=\"fixed-bugs_${date}\"></a>Fixed bugs|g" $fileMd

sed -i "/Scroll up slightly after the jump./r $contents" $fileMd #puts list of contents after `Contents` line near top of markdown file
sed -E -i 's|Scroll up slightly after the jump.|Scroll up slightly after the jump.\n|g' $fileMd

done

cd ..

fi

done

cd ..

done