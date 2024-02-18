yesterday=$(date -d '-1 day' "+%Y%m%d")

tar --zstd -cf $yesterday.tar.zst $yesterday/
rsync -av $yesterday.tar.zst /mnt/storagebox/mvg-data/