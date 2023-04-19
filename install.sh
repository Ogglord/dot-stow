#!/bin/bash

## usage
### Basic install
## ./install.sh
##
### Custom install
## CONFIG_DIR="${HOME}" install.sh --branch [<branch_name>]

main() {

    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)
    local DOT_DIR="$HOME/.local/share/dot"
    local DOT_CONFIG_DIR="${CONFIG_DIR:-$HOME}/.config/dot"
    local GIT_URL="https://github.com/Ogglord/dot-stow.git"
    local CONFIG_FILE="$DOT_CONFIG_DIR/dot.config"

    echo "Installing dot ($DATE)..."
    ## check for pre-requisites
    PACKAGES="stow git"
    MISSING=$(dpkg --get-selections $PACKAGES | grep -v 'install$' | awk '{ print $6 }')

    # Check if additional apps are required to be installed
    if [[ -n "$MISSING" ]]; then
        echo "Please wait while installing $MISSING..."
        sudo apt-get install -y --no-upgrade "$MISSING" > /dev/null 2>&1    
    fi
    # check if DOT_DIR already exists
    [[ -d "$DOT_DIR" ]] && {
        #echo "dot is already installed in '$DOT_DIR'!"
        read -rp "dot is already installd. Reinstall dot? [y/N] "
        echo ""
        [[ $REPLY == "n" ]] && {
            echo "❕ skipped!"
            return
        }
        echo "Reinstalling dot..."
        rm -rf "$DOT_DIR"
    }


    [[ $1 == "--branch" || $1 == "-b" && -n $2 ]] && local BRANCH="$2"
    ## install dot
    git clone -b "${BRANCH:-main}" "${GIT_URL}" "$DOT_DIR" > /dev/null 2>&1 || { echo "❌ Failed to install dot" && return 2 ; }
    
    ## symlink dot -> dot.sh
    ln -sf "${DOT_DIR}/dot.sh" "${DOT_DIR}/dot"

    ## log installed revision (for future update checks)
    REVISION=$( cd "$DOT_DIR" && git rev-parse origin/main )

    ## create standard config file if it does not exist...
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$DOT_CONFIG_DIR"        
        touch "$CONFIG_FILE"
    fi

    git config -f "$CONFIG_FILE" core.installid "$ID"
    git config -f "$CONFIG_FILE" core.branch "${BRANCH:-main}"
    git config -f "$CONFIG_FILE" core.revision "${REVISION:-}"
    git config -f "$CONFIG_FILE" core.url "${GIT_URL}"
    git config -f "$CONFIG_FILE" git.dotfiles.remote origin
    git config -f "$CONFIG_FILE" git.dotfiles.branch main
    git config -f "$CONFIG_FILE" path.dotfiles "${HOME}/.dotfiles"
    git config -f "$CONFIG_FILE" path.target "${HOME}"
    git config -f "$CONFIG_FILE" path.stow "$(which stow)"

    ## Check if dot is in PATH
    if [[ ":$PATH:" == *":$DOT_DIR:"* ]]; then
      echo "$DOT_DIR is in your PATH. Great!"
    else
        echo "❌ You need to add $DOT_DIR to your PATH in order to run \`dot\` commands"
        echo "Execute the following command once:"
        echo        
        if [[ -f "${HOME}/.zshrc" ]]; then
            echo "    echo 'export PATH=\"$DOT_DIR:\$PATH\"' >> ${HOME}/.zshrc"
        else           
            echo "    echo 'export PATH=\"$DOT_DIR:\$PATH\"' >> ${HOME}/.profile"
        fi  
        echo             
    fi
    
    echo "dot installed!";
}

main "$@"