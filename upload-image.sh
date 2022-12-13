#! /bin/bash

verintToken=""
communityUrl="" #example: docs.mysite.com
galleryId="" #example: 123
year="" #example: 2024
month="" #example: 03
day="" #example: 06

yearDir=$year
dateDir=$year-$month-$day

cd $yearDir
cd $dateDir
cd media

find *.json ! -name 'key.json' -type f -exec rm -f {} + #remove old file if exists
find *.txt -type f -exec rm -f {} +

jq -r '.[] | "\(.filename)|\(.title)"' key.json |
    while IFS="|" read -r filename title; do

name="${filename%.*}" #used for naming output files at end of script

uuid=$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}') #this generates a random uuid

for file in $filename; do

echo $file
split -b10M -a3 --numeric-suffixes=100 $file part.
partlist=( part.* )
numparts=${#partlist[@]}
for part in ${partlist[@]}; do
 i=$(( ${part##*.}-100 ))

curl -Si \
 https://$communityUrl/api.ashx/v2/cfs/temporary.json \
  -H 'Rest-User-Token: $verintToken' \
  -F UploadContextId=$uuid \
  -F FileName=$file \
  -F TotalChunks=$numparts \
  -F CurrentChunk="$i" \
  -F 'file=@'$part

done
rm ${partlist[@]}

curl -Si \
  https://$communityUrl/api.ashx/v2/media/$galleryId/files.json \
  -H 'Rest-User-Token: $verintToken' \
  -F ContentType=application/zip \
  -F FileName=$file \
  -F FileUploadContext=$uuid \
  -F "Name=$title"

done | tee $name.txt

perl -p -i -e 's/\R//g;' $name.txt #remove hard returns

sed 's/.*\({"Media":{.*Errors":\[\]}\)/\1/' < $name.txt > $name.json #extract json from string

jq -s '.[] | .Media | .File | .FileUrl' < $name.json >> url.txt #get image verint url from json

done

perl -i -0pe 's/"//g' url.txt #remove quotes