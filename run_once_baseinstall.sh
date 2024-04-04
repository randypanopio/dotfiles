#!/bin/bash
#TODO ensure dotfiles are synced, but recursive chezmoi apply.. 
echo "🐠 Running run once base install script..."

# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

# installer based install 
function check_and_install_app() {
    app_name="$1"
    installer="$2"
    update="$3"
    elevated="$4" # pass su/sudo if it should be elevated access

    if ! which "$app_name" > /dev/null 2>&1; then
        $print "🚧 ${warn_highlight} ${app_name} ${reset_format} not found. It might exist eleswhere, but was not found in system path. Installing globally using $installer..."

        # run command in a subshell separate from the script's scope, maybe security? idunnolol
        ($elevated $installer install $app_name)
    else
        $print "⚓ ${highlight} ${app_name} ${reset_format} already installed. located at: $(which "$app_name")"
        if [[ $update == "update" ]]; then
        $print "⬆️  Updating ${highlight} ${app_name} ${reset_format}"

        ($elevated $installer upgrade ${app_name})
        fi
    fi
}

# =============== actual executed scripts ===============
# setup privilege access
privileged_access="sudo"
function set_privileged_access({
    # I was initially running su vs sudo but running sudo on all is probably fine, will need to change when running for powershell
    privileged_access="sudo"
    $print "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    $print "\n${highlight}"
    $print "**WARNING:** Prompting you with sudo access, this is to pass sudo access to specific install commands"
    $print "${reset_format}"
    $privileged_access echo "** granted ${privileged_access} privilege **"
})
set_privileged_access

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
            $print "Detected Ubuntu system."
            os_installer="apt-get"
            $print "OS installer set to: ${highlight} ${os_installer} ${reset_format} updating installer...\n"
            $privileged_access $os_installer update
        elif [[ $cat_os_release =~ "ID=debian" ]]; then
            os_distro="ubuntu"
            $print "Detected Debian system."
            os_installer="apt-get"
            $print "OS installer set to: ${highlight} ${os_installer} ${reset_format} updating installer...\n"
            $privileged_access $os_installer update
        else
            $print "${warn_highlight}"
            $print "⚠️ Unsupported OS: ${os_name}, or distro: ${os_distro}, halting script..."
            $print "${reset_format}"
            exit 1
        fi
        
    elif [[ $os_name == "Darwin" ]]; then
        # TODO figure out macOS mess
        os_installer="apt"
        $print "Detected macOS system."
        $print "OS installer set to: ${highlight} ${os_installer} ${reset_format} updating installer...\n"
        $privileged_access $os_installer update
    else
        $print "${warn_highlight}"
        $print "⚠️ Unsupported OS: ${os_name} halting script..."
        $print "${reset_format}"
        exit 1
    fi    
}
set_os_vars

# Install ZSH - base shell for everything
$print "\n${highlight}"
$print "🐠 Installing and setting default shell to Zsh"
$print "${reset_format}"
# safe to assume zsh is installed on a macos platform probably...
function install_zsh(){
    if [[ $os_name == "Linux" ]]; then        
        check_and_install_app "zsh" "${os_installer}" "${privileged_access}"
    elif [[ $os_name == "Darwin" ]]; then
        if which zsh >/dev/null 2>&1; then
            $print "⚓ ${highlight} zsh ${reset_format} already installed. located at: $(which "$app_name")"
        else
            $print "${warn_highlight}"
            $print "⚠️ Zsh not found on a Mac Installation, that shouldn't have happened! exiting..."
            $print "${reset_format}"
            exit 1
        fi
    else 
        $print "${warn_highlight}"
        $print "⚠️ Unsupported OS: ${os_name} halting script..."
        $print "${reset_format}"
        exit 1
    fi
    
    # Check installation status, add to path if missing
    #grep if export PATH="/usr/local/bin:$PATH" is already set in ~/.zshrc if not then add
    

    # Do another installation check
    if which zsh >/dev/null 2>&1; then
        $print "✅ zsh installation successful!"
    else
        $print "❌ zsh installation failed. exiting..."
        exit 1
    fi

    # Check if zsh is the current default shell
    new_shell="zsh"
    current_shell=$(echo $SHELL)

    if [[ "$current_shell" == $(which zsh) ]]; then
        $print "⚓ zsh is already your default shell."
    else
        $print "changing default shell to $new_shell."
        $privileged_access chsh -s $(which $new_shell)
        
        # Verify the change, I dont think I can get this to easily work..
        # if [[ "$current_shell" == $(which $new_shell) ]]; then
        #     $print "✅ $new_shell has been set as your default shell successfully."
        # else
        #     $print "${warn_highlight}"
        #     $print "⚠️  An error occurred while setting $new_shell as the default shell! May need to manually change default shell to $new_shell."
        #     $print "${reset_format}"
        # fi
        $print "${highlight}"
        $print "⚠️  Skipping validation of setting $new_shell as the default shell! May need to manually change default shell to $new_shell."
        $print "${reset_format}"
    fi

}
install_zsh


# Install Homebrew
$print "\n${highlight}"
$print "🐠 Installing Homebrew and adding to Shell Paths"
$print "${reset_format}"
function install_homebrew() {
    if which brew >/dev/null 2>&1; then
        $print "⚓🍺 ${highlight} Homebrew ${reset_format} installed! found at: $(which brew) "
        return 0
    else
        # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
        brew_command="NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""      
        $print "🚧 ${highlight} Installing 🍺 Homebrew... ${reset_format}"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Check installation status
    if which brew >/dev/null 2>&1; then
        $print "✅ brew installation successful!"
        return 0
    else
        $print "❌ brew installation failed. exiting..."
        exit 1
    fi
}
install_homebrew

# Language and Tooling
$print "\n${highlight}"
$print "🐠 Installing Languages and Tooling"
$print "${reset_format}"
check_and_install_app "python3" "$os_installer" 

# Tools
$print "\n${highlight}"
$print "🐠 Installing Tools"
$print "${reset_format}"
check_and_install_app "git" "$os_installer" "update"
check_and_install_app "build-essential" "$os_installer" 
# also check these in case they dont get installed
check_and_install_app "gcc" "$os_installer"
check_and_install_app "clang" "$os_installer"
check_and_install_app "valgrind" "$os_installer"
check_and_install_app "zsh" "brew"

# Productivity
$print "\n${highlight}"
$print "🐠 Installing Productivity Apps"
$print "${reset_format}"
check_and_install_app "tmux" "brew" # my fave multiplexer
check_and_install_app "nvim" "brew" # fallback editor, but vscode is great for hooking debuggers so...
check_and_install_app "chezmoi" "brew" # syncing dotfiles, which this script is originally going to execute, but if manually running then we install

# Others
$print "\n${highlight}"
$print "🐠 Installing Utilities and Misc. Applications"
$print "${reset_format}"
# check_and_install_app "docker" "$os_installer" # we love containers!
check_and_install_app "git" "$os_installer" # howd you run this script without git?
check_and_install_app "openfortivpn" "$os_installer" # vpn client for fortinet vpns 

# custom installations
# oh-my-zsh - a zsh extension, for my themes and plugins (such as zsh-autocomplete)
install_omyzsh(){
    zsh_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    oh_my_zsh_installer="sh -c "$(curl -fsSL $zsh_url)"" # taken from https://ohmyz.sh/#install
    if ! command -v zsh >/dev/null 2>&1; then
      $print "⚠️ Zsh not found!"
      # TODO add to list of failed installs
      return 1
    fi
    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        $print "⚓ ${highlight} Oh My Zsh ${reset_format} already installed."
        return 0  # Indicate success
    fi
    # Proceed with installation
    $print "Installing Oh My Zsh remote script: $zsh_url"
    (eval "$oh_my_zsh_installer")  # Execute installation in a subshell

    # Check installation status
    if [ -d "$HOME/.oh-my-zsh" ]; then
        $print "✅ Oh My Zsh installation successful!"
        return 0  # Indicate success
    else
        $print "❌ Oh My Zsh installation failed."
        return 1  # Indicate error
    fi
}

# code - vscode editor plugin (might be useful for ssh vscode integrations)

$print "\n\n🐠 Run once base install script complete. Restart/Logout to finish setup."
exit 0