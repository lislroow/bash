

for file in *; do
  md5=$(md5sum "$file" | awk '{print $1}')
  ext="${file##*.}"
  newFile="$md5.$ext"
  mv "$file" $newFile
done

list=(a.ext)
for file in ${list[*]}; do
  md5=$(md5sum "$file" | awk '{print $1}')
  ext="${file##*.}"
  newFile="$md5.$ext"
  mv "$file" $newFile
done


ext="ext"
for file in *; do
  fileNm="${file%.*}"
  newFile="$fileNm.$ext"
  mkvmerge -o $newFile "$file"
done

for file in $(ls *[SHANA]*); do
  fileNm="${file/\[SHANA\]/}"
  rm -rf $fileNm
done