#!/bin/bash

# TODO: when asking for an action, show the file path in dots-hyprland
# TODO: ignore .config/foot/foot.ini, .config/starship.toml, .config/fish/config.fish
# TODO: find the most recent commits changing file showing them to give user better overview of changes that were made

# Set the paths
DOTS_HYPRLAND_PATH="$HOME/dev/dots-hyprland/.config"
NIXOS_CONFIG_PATH="$HOME/dev/t-wilkinson/nixos-config/homes/trey/.config"

# Arrays to store summaries
declare -a new_dirs
declare -a new_files
declare -a updated_files

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if required commands exist
for cmd in git rsync diff colordiff; do
  if ! command_exists "$cmd"; then
    echo "Error: $cmd is required. Please install it and try again."
    exit 1
  fi
done

# Use colordiff if available, otherwise use regular diff
DIFF_CMD=$(command_exists colordiff && echo "colordiff" || echo "diff")

# Update dots-hyprland repository
echo "Updating dots-hyprland repository..."
cd "$DOTS_HYPRLAND_PATH" || exit
git pull
if [ $? -ne 0 ]; then
  echo "Error: Failed to pull changes from dots-hyprland repository."
  exit 1
fi

# Function to handle file conflicts
handle_conflict() {
  local src="$1"
  local dest="$2"
  local relative_path="${dest#$NIXOS_CONFIG_PATH/}"

  if [ -f "$dest" ]; then
    if ! cmp -s "$src" "$dest"; then
      # Check if the change is only an addition
      if diff "$dest" "$src" | grep -q '^<'; then
        # There are deletions or conflicting changes
        echo "Conflict detected for file: $relative_path"
        $DIFF_CMD -u "$dest" "$src"
        echo "Choose an action:"
        echo "  [1] Use dots-hyprland version (overwrite local)"
        echo "  [2] Keep local version (ignore dots-hyprland changes)"
        echo "  [3] Edit dots-hyprland version"
        echo "  [4] Skip this file"
        while true; do
          read -r -p "Enter your choice (1-4): " choice </dev/tty
          case $choice in
          1)
            cp "$src" "$dest"
            echo "Updated with dots-hyprland version."
            updated_files+=("$relative_path (user-approved overwrite)")
            break
            ;;
          2)
            echo "Kept local version."
            break
            ;;
          3)
            ${VISUAL:-${EDITOR:-vi}} "$src"
            cp "$src" "$dest"
            echo "Edited and updated with modified dots-hyprland version."
            updated_files+=("$relative_path (user-edited)")
            break
            ;;
          4)
            echo "Skipped."
            break
            ;;
          *)
            echo "Invalid choice. Please enter a number between 1 and 4."
            ;;
          esac
        done
      else
        # Only additions, update automatically
        cp "$src" "$dest"
        updated_files+=("$relative_path (auto-updated)")
      fi
    fi
  else
    # New file, add automatically
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    new_files+=("$relative_path")
  fi
}

# Function to handle directory synchronization
sync_directories() {
  local src_dir="$1"
  local dest_dir="$2"

  # Create directories that don't exist in nixos-config
  find "$src_dir" -type d | while read -r dir; do
    relative_dir="${dir#$src_dir/}"
    target_dir="$dest_dir/$relative_dir"
    if [ ! -d "$target_dir" ]; then
      mkdir -p "$target_dir"
      new_dirs+=("$relative_dir")
    fi
  done
}

# Sync directories
echo "Syncing directories..."
sync_directories "$DOTS_HYPRLAND_PATH" "$NIXOS_CONFIG_PATH"

# Sync changes to nixos-config
echo "Syncing changes to nixos-config..."
find "$DOTS_HYPRLAND_PATH" -type f | while read -r file; do
  src="$file"
  dest="${file/$DOTS_HYPRLAND_PATH/$NIXOS_CONFIG_PATH}"
  handle_conflict "$src" "$dest"
done

echo "Update process completed."

# Print summary of changes
echo -e "\nSummary of changes:"
echo "--------------------"
if [ ${#new_dirs[@]} -gt 0 ]; then
  echo "New directories created:"
  printf -- "- %s\n" "${new_dirs[@]}"
fi
if [ ${#new_files[@]} -gt 0 ]; then
  echo "New files added:"
  printf -- "- %s\n" "${new_files[@]}"
fi
if [ ${#updated_files[@]} -gt 0 ]; then
  echo "Files updated:"
  printf -- "- %s\n" "${updated_files[@]}"
fi
if [ ${#new_dirs[@]} -eq 0 ] && [ ${#new_files[@]} -eq 0 ] && [ ${#updated_files[@]} -eq 0 ]; then
  echo "No changes were made."
fi

echo -e "\nPlease review the changes in your nixos-config folder."

# Optionally, you can add a git commit and push for nixos-config here
while true; do
  read -r -p "Do you want to commit and push changes to nixos-config? (y/n): " commit_choice </dev/tty
  case $commit_choice in
  [Yy])
    cd "$HOME/dev/t-wilkinson/nixos-config" || exit
    git add .
    git status
    read -r -p "Enter commit message: " commit_message </dev/tty
    git commit -m "$commit_message"
    git push
    echo "Changes committed and pushed to nixos-config repository."
    break
    ;;
  [Nn])
    echo "Changes were not committed. You can manually review and commit them later."
    break
    ;;
  *)
    echo "Invalid input. Please enter 'y' or 'n'."
    ;;
  esac
done

echo "Script completed."
