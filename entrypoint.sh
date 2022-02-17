#!/bin/sh
cd arangodb

operation="$1"
changed_filenames_file="$2"

# temporary file for diffs
temp_file=".clang-format-$$.reformat.tmp"
# clean up after ourselves
trap "rm -f $temp_file" EXIT SIGINT SIGTERM SIGHUP

# output version info
clang-format --version

# count number of lines in $changed_filenames_file
checked=$(wc -l "$changed_filenames_file" | cut -d " " -f 1)

# read $changed_filenames_file line by line and run clang-format on each filename
echo "checking $checked file(s)..."
formatted=0
while read -r file
  do 
    # some .h files are currently misinterpreted as Objective-C files by clang-format,
    # so we pretend that they are .cpp files. this requires piping the input into
    # clang-format as well, unfortunately.
    if [[ "$operation" = "validate" ]]
    then
      # force .cpp ending to work around clang-format language interpretation
      nicename="$(basename "$file").cpp"
      git show ":0:$file" | clang-format -Werror -ferror-limit=0 --dry-run --assume-filename="$nicename" -style=file 
      status=$?
      if [[ $status -eq 0 ]]
      then
        # all good
      elif [[ $status -eq 1 ]]
      then
        echo "file needs reformatting: $file"
        echo
        formatted="$((formatted+1))"
      else
        echo "unknown error formatting file: $file"
        exit 2
      fi
    elif [[ "$operation" = "format" ]]
    then
      cat "$file" | clang-format --assume-filename=test.cpp -style=file > "$temp_file" 
      if [[ "$?" != "0" ]]; then
        echo "error formatting $file"
        exit 1
      fi
      diff -q "$file" "$temp_file" > /dev/null
      if [[ "$?" != "0" ]]; then
        echo "reformatting $file"
        # move is atomic if we are in the same filesystem (hope we are), so we won't
        # end up with halfway written files on reformat if the script is killed
        mv "$temp_file" "$file"
        formatted="$((formatted+1))"
      fi
    else
      echo "unknown operation type: $operation"
      exit 2
    fi

  done < "$changed_filenames_file" 

echo
echo "done - checked $checked file(s), reformatted $formatted file(s)"
if [[ "$formatted" != "0" ]] && [[ "$operation" = "validate" ]]
then
  echo "erroring out because $formatted file(s) need(s) to be reformatted!!!"
  echo
  exit 1
fi
