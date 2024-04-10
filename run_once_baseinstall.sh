#!/bin/bash
# TODO should probably rename me
echo "🐠 Running run once base install script..."
#temp supppress running
exit 0

# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

# installer based install 
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

# =============== actual executed scripts ===============
# setup privilege access
privileged_access="sudo"
function set_privileged_access(){
    # I was initially running su vs sudo but running sudo on all is probably fine, will need to change when running for powershell
    privileged_access="sudo"
    $print "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    $print "\n${highlight}"
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
            exit 1
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
        exit 1
    fi    
}
set_os_vars

# # Install Homebrew
# bash './scripts/brew_install.sh'
# install_exit_code=$?
# if [[ $install_exit_code -eq 0 ]]; then
#     $print "ℹ️  brew_install complete."
# else
#     $print "${warn_highlight}"
#     $print "⚠️ brew_install failed! halting script..."
#     $print "${reset_format}" 
#     exit 1
# fi

# Install zsh
bash './scripts/zsh_install.sh'
install_exit_code=$?
if [[ $install_exit_code -eq 0 ]]; then
    $print "ℹ️  zsh_install complete."
else
    $print "${warn_highlight}"
    $print "⚠️ zsh_install failed! halting script..."
    $print "${reset_format}" 
    exit 1
fi

# Install Language and tooling
bash './scripts/language_install.sh'
install_exit_code=$?
if [[ $install_exit_code -eq 0 ]]; then
    $print "ℹ️  language_install complete."
else
    $print "${warn_highlight}"
    $print "⚠️ language_install failed! halting script..."
    $print "${reset_format}" 
    exit 1
fi
exit 0

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