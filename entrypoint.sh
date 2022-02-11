#!/bin/sh
cd arangodb

changed_filenames_file="$1"

# output version info
clang-format --version

# count number of lines in $changed_filenames_file
checked=$(wc -l "$changed_filenames_file" | cut -d " " -f 1)

# read $changed_filenames_file line by line and run clang-format on each filename
echo "checking $checked file(s)..."
passed=0
formatted=0
while read -r file
  do 
    # some .h files are currently misinterpreted as Objective-C files by clang-format,
    # so we pretend that they are .cpp files. this requires piping the input into
    # clang-format as well, unfortunately.
    git show ":0:$file" | clang-format -Werror -ferror-limit=0 --dry-run --assume-filename=test.cpp -style=file 
    status=$?

    if [[ $status -eq 0 ]]
    then
      # all good
      passed="${passed+1}"
    elif [[ $status -eq 1 ]]
    then
      echo "file needs reformatting: $file"
      formatted="${formatted+1}"
    else
      echo "unknown error formatting file: $file"
      exit 2
    fi
  done < "$changed_filenames_file" 

echo
echo "done - checked $checked file(s), reformatted $formatted file(s)"
if [[ "$formatted" != "0" ]]; then
  echo "erroring out because $formatted file(s) needs to be reformatted!!!"
  exit 1
fi
