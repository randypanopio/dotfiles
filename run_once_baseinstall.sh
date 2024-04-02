#!/bin/bash
echo "🐠 Running run once base install script..."
#TODO ensure dotfiles are synced

# installer based install 
function check_and_install_app() {
    app_name="$1"
    installer="$2"
    update="$3"

    if ! which "$app_name" > /dev/null 2>&1; then
        echo "🚧 ${highlight} ${app_name} ${reset_format} not found. It might exist eleswhere, but was not found in system path. Installing globally using $installer..."
        $installer install $app_name
    else
        echo "⚓ ${highlight} ${app_name} ${reset_format} already installed. located at: $(which "$app_name")"
        if [[ $update == "update" ]]; then
        echo "⬆️  Updating ${highlight} ${app_name} ${reset_format}"
        $installer upgrade ${app_name}
        fi
    fi
}

# formatting - TODO check what executes, if its bash, then suppress
highlight="\033[0;33m"
warn_highlight="\033[0;31m"
reset_format="\033[0m"
# highlight text: ${highlight} <text> ${reset_format} 

# process OS vars and installers
os_name="unknown"
os_distro="unknown"
os_installer="unknown"
function set_os_vars(){
    os_name=$(uname)
    if [[ $os_name == "Linux" ]]; then      
        cat_os_release=$(cat /etc/os-release)
        if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
            os_distro="ubuntu"
            echo "Detected Ubuntu system."
            os_installer="apt-get"
            echo "OS installer set to: ${highlight} ${os_installer} ${reset_format} updating installer...\n"
            $os_installer update
        elif [[ $cat_os_release =~ "ID=debian" ]]; then
            os_distro="ubuntu"
            echo "Detected Ubuntu system."
            os_installer="apt-get"
            echo "OS installer set to: ${highlight} ${os_installer} ${reset_format} updating installer...\n"
            $os_installer update
        else
            echo "${warn_highlight}"
            echo "⚠️ Unsupported OS: ${os_name}, or distro: ${os_distro}, halting script..."
            echo "${reset_format}"
            exit 1
        fi
        
    elif [[ $os_name == "Darwin" ]]; then
        # TODO figure out macOS mess
        os_installer="apt"
        echo "OS installer set to: ${highlight} ${os_installer} ${reset_format} updating installer...\n"
    else
        echo "${warn_highlight}"
        echo "⚠️ Unsupported OS: ${os_name} halting script..."
        echo "${reset_format}"
        exit 1
    fi    
}
set_os_vars

# Install ZSH - base shell for everything
echo "\n${highlight}"
echo "🐠 Installing and setting default shell to Zsh"
echo "${reset_format}"
# safe to assume zsh is installed on a macos platform probably...
function install_zsh(){
    if [[ $os_name == "Linux" ]]; then        
        check_and_install_app "zsh" "${os_installer}"
    elif [[ $os_name == "Darwin" ]]; then
        if which zsh >/dev/null 2>&1; then
            echo "⚓ ${highlight} zsh ${reset_format} already installed. located at: $(which "$app_name")"
        else
            echo "${warn_highlight}"
            echo "⚠️  Zsh not found on a Mac Installation, that shouldn't have happened! exiting..."
            echo "${reset_format}"
            exit 1
        fi
    else 
        echo "${warn_highlight}"
        echo "⚠️ Unsupported OS: ${os_name} halting script..."
        echo "${reset_format}"
        exit 1
    fi
    
    # Check installation status
    if which zsh >/dev/null 2>&1; then
        echo "✅ zsh installation successful!"
    else
        echo "❌ zsh installation failed. exiting..."
        exit 1
    fi

    # Check if zsh is the current default shell
    current_shell=$(echo $SHELL) # TODO fix

    if [[ "$current_shell" == "zsh" ]]; then
        echo "⚓ zsh is already your default shell."
    else
        echo "changing default shell to zsh."
        # TODO figure me out, way to execute without user input
        # sudo chsh -s $(which zsh)
        # # Verify the change
        # new_shell=$(grep /zsh /etc/passwd | cut -d ":" -f 1)
        # echo "$(echo $SHELL)"
        if [[ "$new_shell" == "zsh" ]]; then
            echo "✅ zsh has been set as your default shell successfully."
        else
            echo "${warn_highlight}"
            echo "⚠️ An error occurred while setting zsh as the default shell. ${os_name} halting script..."
            echo "${reset_format}"
            exit 1
        fi
    fi
}
install_zsh

#grep if export PATH="/usr/local/bin:$PATH" is already set in ~/.zshrc if not then add

# Install Homebrew
echo "\n${highlight}"
echo "🐠 Installing Homebrew and adding to Shell Paths"
echo "${reset_format}"
function install_homebrew() {
    if which brew >/dev/null 2>&1; then
        echo "⚓🍺 ${highlight} Homebrew ${reset_format} installed! found at: $(which brew) "
        return 0
    else
        # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
        brew_command="NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""      
        echo "🚧 ${highlight} Installing 🍺 Homebrew... ${reset_format}"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Check installation status
    if which brew >/dev/null 2>&1; then
        echo "✅ brew installation successful!"
        return 0
    else
        echo "❌ brew installation failed. exiting..."
        exit 1
    fi
}
install_homebrew

# Language and Tooling
echo "\n${highlight}"
echo "🐠 Installing Languages and Tooling"
echo "${reset_format}"
check_and_install_app "python3" "$os_installer" 

# Tools
echo "\n${highlight}"
echo "🐠 Installing Tools"
echo "${reset_format}"
check_and_install_app "git" "$os_installer" "update"
check_and_install_app "build-essential" "$os_installer" 
# also check these in case they dont get installed
check_and_install_app "gcc" "$os_installer"
check_and_install_app "clang" "$os_installer"
check_and_install_app "valgrind" "$os_installer"
check_and_install_app "zsh" "brew"

# Productivity
echo "\n${highlight}"
echo "🐠 Installing Productivity Apps"
echo "${reset_format}"
check_and_install_app "tmux" "brew" # my fave multiplexer
check_and_install_app "nvim" "brew" # fallback editor, but vscode is great for hooking debuggers so...
check_and_install_app "chezmoi" "brew" # syncing dotfiles, which this script is originally going to execute, but if manually running then we install

# Others
echo "\n${highlight}"
echo "🐠 Installing Utilities and Misc. Applications"
echo "${reset_format}"
# check_and_install_app "docker" "$os_installer" # we love containers!
check_and_install_app "git" "$os_installer" # howd you run this script without git?
check_and_install_app "openfortivpn" "$os_installer" # vpn client for fortinet vpns 

# custom installations
# oh-my-zsh - a zsh extension, for my themes and plugins (such as zsh-autocomplete)
install_omyzsh(){
    zsh_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    oh_my_zsh_installer="sh -c "$(curl -fsSL $zsh_url)"" # taken from https://ohmyz.sh/#install
    if ! command -v zsh >/dev/null 2>&1; then
      echo "⚠️ Zsh not found!"
      # TODO add to list of failed installs
      return 1
    fi
    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "⚓ ${highlight} Oh My Zsh ${reset_format} already installed."
        return 0  # Indicate success
    fi
    # Proceed with installation
    echo "Installing Oh My Zsh remote script: $zsh_url"
    (eval "$oh_my_zsh_installer")  # Execute installation in a subshell

    # Check installation status
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "✅ Oh My Zsh installation successful!"
        return 0  # Indicate success
    else
        echo "❌ Oh My Zsh installation failed."
        return 1  # Indicate error
    fi
}

# code - vscode editor plugin (might be useful for ssh vscode integrations)

echo "\n\n🐠 Run once base install script complete."