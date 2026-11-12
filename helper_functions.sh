#!/bin/bash

# sync_repo_to_home
# Copies the entire contents of the current repository root to a structured backup directory
# inside the user's home directory ($HOME), preserving the relative path structure.
#
# This function must be sourced: source helper_functions.sh
# It uses 'rsync' with the --exclude-from option for the most robust and simple approach.
#
# Usage: 
# - sync_repo_to_home (No arguments: copies everything)
# - sync_repo_to_home --exclude <path/to/exclusions.txt> (Copies excluding patterns listed in the file)
#
sync_repo_to_home() {
    # --- Setup ---
    local repo_root=$(pwd)
    local base_name=$(basename "${repo_root}")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target_dir="${HOME}/${base_name}_backup_${timestamp}"
    
    # --- Setup ---
    local repo_root=$(pwd)
    local base_name=$(basename "${repo_root}")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target_dir="${HOME}/${base_name}_backup_${timestamp}"
    
    local exclude_file="${repo_root}/.config/exclude"
    local rsync_options=""
    local found_exclusions=0
    
    # Check if the hardcoded exclusion file exists
    if [ -f "${exclude_file}" ]; then
        echo "Using exclusion file: ${exclude_file}"
        # Construct the exclusion option string
        rsync_options="--exclude-from=\"${exclude_file}\""
        found_exclusions=1
    else
        echo "Exclusion file not found at ${exclude_file}. Syncing everything."
        rsync_options=""
    fi
    # --- Core Logic ---
    
     # Determine rsync options and validation
     if [ "$found_exclusions" -eq 1 ]; then
         # The options are already set in setup
         : # No action needed here, rsync_options is set
     else
         rsync_options=""
     fi

    # Create the target directory first
    mkdir -p "${target_dir}"
    
    echo "--- Starting Repository Sync ---"
    echo "Source Repository Root: ${repo_root}"
    echo "Target Backup Directory: ${target_dir}"

    # Construct and execute the rsync command
    # -a: archive mode (preserves permissions, times, etc.)
    # -v: verbose output
    # The trailing slash on "${repo_root}/" is crucial: it copies the *contents* 
    # of repo_root, not the folder named repo_root itself, into target_dir.
    
    # Use eval to correctly expand potentially complex variables like rsync_options
    SYNC_COMMAND="rsync -av ${rsync_options} \"${repo_root}/\" \"${target_dir}\""
    
    echo "Executing command: ${SYNC_COMMAND}"
    
    echo "Executing command: ${SYNC_COMMAND}"
    
    if eval "$SYNC_COMMAND"; then
        ACTION_DESC="repository contents"
        if [ "$found_exclusions" -eq 1 ]; then
            ACTION_DESC="(Skipped items defined in exclusion file)"
        fi
        
        echo ""
        echo "✅ Successfully synchronized ${ACTION_DESC} to ${target_dir}."
    else
        echo ""
        echo "❌ Error during synchronization. Check if 'rsync' is installed and paths are correct."
        echo "------------------------------"
    fi
}