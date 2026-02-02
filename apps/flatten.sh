#!/bin/bash
# Flatten directory and move it to /tmp/{directory} to make it easier to upload filenames
# Especially useful for gemini as it requires unique file names

# 1. Set up the destination directory with a timestamp to ensure uniqueness
DEST_DIR="/tmp/$(basename $(pwd))"
mkdir -p "$DEST_DIR"

# 2. Find all files recursively (-type f)
# -print0 and IFS= read -r -d '' handles filenames with spaces safely
find . -type f -print0 | while IFS= read -r -d '' file; do

  # 3. Strip the leading "./" from the find output
  # Example: ./dir1/file.txt -> dir1/file.txt
  clean_path="${file#./}"

  # 4. Replace all slashes (/) with dashes (-)
  # Syntax: ${variable//search/replace}
  new_name="${clean_path//\//-}"

  # 5. Copy the file to the destination
  # We use cp -n (no-clobber) to prevent overwriting if collisions occur
  if [ -e "$DEST_DIR/$new_name" ]; then
    echo "⚠️  COLLISION SKIPPED: $new_name already exists."
  else
    cp "$file" "$DEST_DIR/$new_name"
  fi

done

echo "echo $DEST_DIR"
