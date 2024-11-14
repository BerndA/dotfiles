#!/usr/bin/env bash
#
cat << EOF > user.nix
{
 home.username = "$USER";
}
EOF
