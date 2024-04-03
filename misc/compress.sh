#!/bin/bash
set -o errexit


yesterday=$(date -d '-1 day' "+%Y%m%d")

tar --sort=name --zstd -cf $yesterday.tar.zst $yesterday/

rsync -av $yesterday.tar.zst /mnt/storagebox/mvg-data/

rm -r $yesterday/