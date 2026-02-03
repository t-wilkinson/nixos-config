#!/bin/bash
# Flatten directory and move it to /tmp/{directory} to make it easier to upload filenames
# Especially useful for gemini as it requires unique file names

# Set up the destination directory with a timestamp to ensure uniqueness
DEST_DIR="/tmp/$(basename $(pwd))"
mkdir -p "$DEST_DIR"

# Find all files recursively (-type f)
# -print0 and IFS= read -r -d '' handles filenames with spaces safely
find . -type f -print0 | while IFS= read -r -d '' file; do

  # Strip the leading "./" from the find output
  # Example: ./dir1/file.txt -> dir1/file.txt
  clean_path="${file#./}"

  # Replace all slashes (/) with dashes (-)
  new_name="${clean_path//\//-}"

  # Copy the file to the destination
  if [ ! -e "$DEST_DIR/$new_name" ]; then
    ln -sf "$(pwd)/$clean_path" "$DEST_DIR/$new_name"
  fi

  #if [ -e "$DEST_DIR/$new_name" ]; then
  #  echo "⚠️  COLLISION SKIPPED: $new_name already exists."
  #else
  #  cp "$file" "$DEST_DIR/$new_name"
  #fi

done

echo "$DEST_DIR"
