#!/bin/bash
# TODO should probably rename me
echo "🐠 Running run once base install script..."

# ========== utilities ========== #
# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

function check_and_install_app() {
    local application=${1-}
    local installer=${2-$os_installer}
    local elevated=${3-""} # pass su/sudo if it should be elevated access
    local update=${4-""} # for upgrading 

    $print "formatted command: [$elevated $installer install $condition $application]"
    if ! which "$application" > /dev/null 2>&1; then
        $print "🚧 ${warn_highlight} ${application} ${reset_format} not found. It might exist eleswhere, but was not found in system path. Installing globally using $installer..."

        # run command in a subshell separate from the script's scope, maybe security? idunnolol
        $print "command: $elevated $installer install $application"
        ($elevated $installer install $application)
    fi
    if [[ $update == "update" || $update == "yes" || $update == "upgrade" ]]; then
        $print "⬆️  Updating ${highlight} ${application} ${reset_format}"
        ($elevated $installer upgrade $application)
    fi
}

declare -a failed_executions
function terminate_script(){
    exit_code=${1}
    if [[ ${#failed_executions[@]} -gt 0 ]]; then
        $print "${warn_highlight}"
        $print "The following execution steps failed:"
        $print "${reset_format}"
        for step in "${failed_executions[@]}"; do
            $print "- $step"
        done
    else 
        $print "✅ zero issues found"
    fi

    if [[ $exit_code == 1 ]]; then
        $print "${warn_highlight}"
        $print "⚠️  Script was terminated early!"
        $print "${reset_format}"
    else
        $print "${highlight}"
        $print "🐠 Run once base install script complete. Yipee! Restart/Logout to finish setup."
        $print "${reset_format}"
    fi
    exit $exit_code
}

function is_app_available() {
    local application=${1-}
    if command -v $application &> /dev/null; then
        return 0
    else
        return 1
    fi
}
# ========== utilities ========== #

# =============== actual executed scripts ===============
# setup privilege access
privileged_access="sudo"
function set_privileged_access(){
    # I was initially running su vs sudo but running sudo on all is probably fine, will need to change when running for powershell
    privileged_access="sudo"
    $print "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    $print "${highlight}"
    $print "**WARNING:** This script will bypass all install prompt and will install dependancies automatically"
    $print "**WARNING:** Prompting you with sudo access, this is to pass sudo access to specific install commands"
    $print "${reset_format}"
    $privileged_access echo "** granted ${privileged_access} privilege **"
}
set_privileged_access

# process OS vars and installers
os_name="unknown"
os_distro="unknown"
os_installer="unknown"
function set_os_vars(){
    os_name=$(uname)
    if [[ $os_name == "Linux" ]]; then      
        # export DEBIAN_FRONTEND=noninteractive # set unineteractive installation for linux
        # $print "setting an uninetractive installation for Linux: DEBIAN_FRONTEND=noninteractive"
        cat_os_release=$(cat /etc/os-release)
        if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
            os_distro="ubuntu"
            $print "Detected Ubuntu system."
            os_installer="DEBIAN_FRONTEND=noninteractive apt-get -y"
            $print "OS installer set to: ${os_installer} updating installer...\n"
            $privileged_access $os_installer update
        elif [[ $cat_os_release =~ "ID=debian" ]]; then
            os_distro="ubuntu"
            $print "Detected Debian system."
            os_installer="DEBIAN_FRONTEND=noninteractive apt-get -y"
            $print "OS installer set to: ${os_installer} updating installer...\n"
            $privileged_access $os_installer update
        else
            $print "${warn_highlight}"
            $print "⚠️ Unsupported OS: ${os_name}, or distro: ${os_distro}, halting script..."
            $print "${reset_format}"
            terminate_script 1            
        fi
        
    elif [[ $os_name == "Darwin" ]]; then
        os_installer="brew"
        $print "Detected macOS system."
        $print "OS installer set to: ${os_installer} updating installer...\n"
        $privileged_access $os_installer update
    else
        $print "${warn_highlight}"
        $print "⚠️ Unsupported OS: ${os_name} halting script..."
        $print "${reset_format}"
        terminate_script 1
    fi    
}
set_os_vars

# Install git
function install_git() {
    $print "${highlight}"
    $print "🐠 Installing git"
    $print "${reset_format}"
    
    if [[ $(is_app_available "git") -eq 0 ]]; then
        $print "⚓ git installed! found at: $(which git) "
    else
        $print "🚧 installing git"
    fi
}
install_git

# Install Homebrew
function install_homebrew() {
    $print "${highlight}"
    $print "🐠 Installing Homebrew and adding to Shell Paths"
    $print "${reset_format}"

    brew_required="true"

    if [[ $(is_app_available "brew") -eq 0 ]]; then
        $print "⚓🍺 Homebrew installed! found at: $(which brew) "
    else
        $print "🚧 brewing... "
        # Install platform specific
        if [[ $os_name == "Linux" ]]; then
            cat_os_release=$(cat /etc/os-release)
            if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
                if [[ $(uname -m) =~ "aarch64" ]]; then
                    $print "homebrew is not supported on aarch64 architecture 🥲"
                    brew_required="false"
                else
                    $print "🚧 Installing 🍺 Homebrew on $cat_os_release... "
                    # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
                    # subshell without elevated access?
                    (NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")  
                fi
            fi
        elif [[ $os_name == "Darwin" ]]; then
            $print "🚧 Installing 🍺 Homebrew... "
            # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
            # subshell without elevated access?
            (NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
        fi
    fi
    
    if [[ $brew_required == "true" ]]; then
        # Check installation status
        if [[ $(is_app_available "brew") -eq 0 ]]; then
            $print "✅ brew installation successful!"
        else
            local failure="❌ brew installation failed!"
            $print $failure
            failed_executions+=$failure
            terminate_script 1
        fi

        # update brew
        $print "${highlight}"
        $print "⬆️  Updating homebrew and its packages"
        $print "${reset_format}"
        (brew update)
        (brew upgrade)
    fi
}
install_homebrew

# Install zsh
function install_zsh(){
    $print "${highlight}"
    $print "🐠 Installing and setting default shell to Zsh"
    $print "${reset_format}"

    if [[ $(is_app_available "zsh") -eq 0 ]]; then
        $print "⚓ zsh installed! found at: $(which zsh) "
    else
        # Install platform specific
        if [[ $os_name == "Linux" ]]; then
            cat_os_release=$(cat /etc/os-release)
            if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
                $print "🚧 Installing zsh on Ubuntu..."
                $privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y install zsh
            fi
        elif [[ $os_name == "Darwin" ]]; then
            $print "🚧 Installing zsh on MacOS... Though that really shouldn't have happened!"
            (brew install zsh)
        fi
    fi

    # Do another installation check
    if [[ $(is_app_available "zsh") -eq 0 ]]; then
        $print "✅ zsh installation successful!"
    else
        local failure="❌ zsh installation failed"
        $print $failure
        failed_executions+=$failure
        terminate_script 1        
    fi

    # Check if zsh is the current default shell
    $print "current shell: $(echo $SHELL), zsh shell: $(which zsh)"
    if [[ ${SHELL##*/} == "zsh" ]]; then
        $print "⚓ zsh is already your default shell."
    else
        $print "🚧 changing default shell to zsh."
        $privileged_access chsh -s "$(which zsh)"
        
        # Verify the change, I dont think I can get this to easily work..
        # if [[ "$current_shell" == $(which $new_shell) ]]; then
        #     $print "✅ $new_shell has been set as your default shell successfully."
        # else
        #     $print "${warn_highlight}"
        #     $print "⚠️  An error occurred while setting $new_shell as the default shell! May need to manually change default shell to $new_shell."
        #     $print "${reset_format}"
        # fi
        $print "${highlight}"
        $print "⚠️ Skipping validation of setting $new_shell as the default shell! May need to manually change default shell to $new_shell."
        $print "${reset_format}"
    fi

}
install_zsh

# oh-my-zsh - a zsh extension, for my themes and plugins (such as zsh-autocomplete)
install_ohmyzsh(){
    $print "${highlight}"
    $print "🐠 Installing oh-my-zsh"
    $print "${reset_format}"

    # check if zsh is avail    
    if [[ $(is_app_available "zsh") -eq 1 ]]; then
        local failure="⚠️  Zsh not found! Unable to install oh-my-zsh."
        $print "$failure continuing with script"
        failed_executions+=$failure
        return 1
    fi

    zsh_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    oh_my_zsh_installer="sh -c "$(curl -fsSL $zsh_url)"" # taken from https://ohmyz.sh/#install seems platform agnostic
    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        $print "⚓ ${highlight} Oh My Zsh ${reset_format} already installed."
    else
        # Proceed with installation
        $print "Installing Oh My Zsh remote script: $zsh_url"
        (eval "$oh_my_zsh_installer")  # Execute installation in a subshell
        # Check installation status
        if [ -d "$HOME/.oh-my-zsh" ]; then
            $print "✅ Oh My Zsh installation successful!"
        else
            local failure="❌ Oh My Zsh installation failed."
            $print "$failure Proceeding with script, may need to manually install"
            failed_executions+=$failure
            return 1
        fi
    fi

    # update
    $print "${highlight}"
    $print "⬆️  Updating oh-my-zsh"
    $print "${reset_format}"
        
}
install_ohmyzsh

# Install Language and tooling
# bash './chez_scripts-language_install.sh'
# install_exit_code=$?
# if [[ $install_exit_code -eq 0 ]]; then
#     $print "ℹ️  language_install complete."
# else
#     $print "${warn_highlight}"
#     $print "⚠️ language_install failed! halting script..."
#     $print "${reset_format}" 
#     exit 1
# fi

# Language and Tooling
# $print "${highlight}"
# $print "🐠 Installing Languages and Tooling"
# $print "${reset_format}"
# check_and_install_app "python3" "$os_installer" 

# # Tools
# $print "${highlight}"
# $print "🐠 Installing Tools"
# $print "${reset_format}"
# check_and_install_app "git" "$os_installer" "update"
# check_and_install_app "build-essential" "$os_installer" 
# # also check these in case they dont get installed
# check_and_install_app "gcc" "$os_installer"
# check_and_install_app "clang" "$os_installer"
# check_and_install_app "valgrind" "$os_installer"

# # Productivity
# $print "${highlight}"
# $print "🐠 Installing Productivity Apps"
# $print "${reset_format}"
# check_and_install_app "tmux" "brew" # my fave multiplexer
# check_and_install_app "nvim" "brew" # fallback editor, but vscode is great for hooking debuggers so...
# check_and_install_app "chezmoi" "brew" # syncing dotfiles, which this script is originally going to execute, but if manually running then we install

# # Others
# $print "${highlight}"
# $print "🐠 Installing Utilities and Misc. Applications"
# $print "${reset_format}"
# # check_and_install_app "docker" "$os_installer" # we love containers!
# check_and_install_app "git" "$os_installer" # howd you run this script without git?
# check_and_install_app "openfortivpn" "$os_installer" # vpn client for fortinet vpns 

# custom installations
# oh-my-zsh - a zsh extension, for my themes and plugins (such as zsh-autocomplete)


# code - vscode editor plugin (might be useful for ssh vscode integrations)

terminate_script 0