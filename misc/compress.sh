#!/bin/bash
set -o errexit

beforeyesterday=$(date -d '-2 day' "+%Y%m%d")
yesterday=$(date -d '-1 day' "+%Y%m%d")

###
# Created tar from the requests yesterday using zstandard compression
tar --sort=name --zstd -cf $yesterday.tar.zst $yesterday/

###
# Test tar integrity by listing its content
tar -tf $yesterday.tar.zst > /dev/null

###
# Copy compressed file into storagebox for public access
rsync -av $yesterday.tar.zst /mnt/storagebox/mvg-data/

###
# Remove the day before yesterday
rm -r $beforeyesterday/

###
# Perform healthcheckping if all previous commands succeed
curl "https://hc-ping.com/8dbf4a8e-0629-4876-899c-6d702c754bc1"