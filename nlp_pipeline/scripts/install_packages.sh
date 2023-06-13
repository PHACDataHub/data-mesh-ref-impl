#!/bin/bash

if [[ $(uname -s) == 'Darwin' ]]; then
    which -s brew
    if [[ $? != 0 ]] ; then
        # Install Homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        brew upgrade
    fi
    brew list jq &>/dev/null || brew install jq
    brew list wget &>/dev/null || brew install wget
else
    sudo apt install jq wget -y
fi
