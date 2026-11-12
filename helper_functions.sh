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
    
    local exclude_file=""
    local rsync_options=""
    local found_exclusions=0
    
    # Argument parsing for optional exclusion file
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --exclude)
                if [ -n "$2" ] && [ "${2:0:1}" != - ]; then
                    exclude_file="$2"
                    shift # past argument
                else
                    echo "Error: --exclude requires a file path." >&2
                    return 1
                fi
                shift # past value
                ;;
            *)
                echo "Warning: Unknown parameter passed: $1 (Ignoring)" >&2
                ;;
        esac
        shift # Consume the argument whether it was a flag or a value
    done

    # --- Core Logic ---
    
    # Determine rsync options and validation
    if [ -n "${exclude_file}" ]; then
        if [ ! -f "${exclude_file}" ]; then
            echo "Error: Exclusion file not found at ${exclude_file}" >&2
            return 1
        fi
        echo "Exclusion File: ${exclude_file}"
        # Construct the exclusion option string
        rsync_options="--exclude-from=\"${exclude_file}\""
        found_exclusions=1
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