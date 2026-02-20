#!/usr/bin/env bash
#

read -p "Enter github username:" GH_USER
read -p "Enter github email:" GH_EMAIL
cat << EOF > user.nix
{
 home.username = "$USER";
 programs.git.settings.user.name = "$GH_USER";
 programs.git.settings.user.email = "$GH_EMAIL";
}
EOF
