#!/usr/bin/env bash
OLD_VERSION=${1-"26.05"}
NEW_VERSION=${2-"26.11"}
TMP_FILE=$(mktemp)
nix-channel --list > "$TMP_FILE"

COMMANDS=()
while read channel_name channel_url; do 
  NEW_URL=$(echo "$channel_url" | sed "s#${OLD_VERSION}#${NEW_VERSION}#g")
  COMMANDS+=("nix-channel --remove '$channel_name'")
  COMMANDS+=("nix-channel --add '$NEW_URL' '$channel_name'")
done < "$TMP_FILE"

rm "$TMP_FILE"
COMMANDS+=("nix-channel --update")

printf '%s\n' "${COMMANDS[@]}"

