#!/bin/bash

function get_os_info() {
    os_name=$(uname -s)
    kernel_name=$(uname -r)
    architecture=$(uname -m)

    if [[ "$os_name" == "Linux" ]]; then
    # Try using /etc/os-release (more reliable for distro info)
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release  # Load os release variables
            $print "ASDASDASD"
            linux_distro="$NAME"
        else
            # Fallback to lsb_release if available
            if which lsb_release &> /dev/null; then
                linux_distro=$(lsb_release -is)
            else
                linux_distro="Unknown Linux Distro"
            fi
        fi
    fi

    if [[ "$os_name" == "Linux" && "$architecture" == *"x86_64"* ]]; then
        echo "⚓ Operating System: $os_name"
        echo "⚓ Kernel Name: $kernel_name"
        echo "⚓ Architecture: $architecture"
        echo "⚓ Linux Distribution: $linux_distro"
    else
        echo "⚓ Incorrect params, skipping Ubuntu x64 Initalization"
        exit 0
    fi
    echo "🐠 Running Ubuntu x86 Initalization Script"
}
get_os_info

# ========== utilities ========== #
# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

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
        $print "⚓ Run once base install script complete. Yipee! Restart/Logout to finish setup."
        $print "${reset_format}"
    fi
    exit "$exit_code"
}

function is_app_available() {
    local application=${1-}
    if command -v "$application" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

function install_application() {
    local application=${1-}
    local installer_arg=${2-$os_installer}

    # check if it is already installed
    if [[ $(is_app_available "$application") -eq 0 ]]; then
        $print "${highlight}"
        $print "⚓ $application installed! found at: $(which "$application")"
        $print "${reset_format}"
    else
        $print "${highlight}"
        $print "🐠 Installing $application"
        $print "${reset_format}"

        # format the correct install command and update command respectively (and if elevated)
        local command=""
        if [[ $installer_arg == "brew" ]]; then 
            command="brew install --quiet $application"
        else
            # default to os_installer 
            command="$privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y install $application"
        fi
        $print "⚓ formatted command: [$command]"
        ($command)

        # validate if application installed succesfully
        if [[ $(is_app_available "$application") -eq 0 ]]; then
            $print "✅ $application installation successful!"
        else
            local failure="❌ $application installation failed!"
            $print "$failure"
            failed_executions+=("$failure")
            return 1
        fi
    fi    

    # update application
    $print "⬆️  Updating ${highlight}${application}${reset_format}"
    if [[ $installer_arg == "brew" ]]; then 
        (brew upgrade --quiet $application)
    else
        ($privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y upgrade $application)
    fi
    $print "⚓${highlight} $application install and upgrade complete.${reset_format}"
}
# ========== utilities ========== #

# ========== installs ========== #
# setup privilege access
privileged_access="sudo"
os_installer="apt-get"
# Requests sudo perms from the user, and updates package manager
function set_installer_access(){
    privileged_access="sudo"
    $print "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    $print "${highlight}"
    $print "**WARNING:** This script will bypass all install prompt and will install dependancies automatically"
    $print "**WARNING:** Prompting you with sudo access, this is to pass sudo access to specific install commands"
    $print "${reset_format}"
    $privileged_access echo "** granted ${privileged_access} privilege **"

    # set apt-get and check access
    $print "⚓  installer set to: ${os_installer} updating installer...\n"

    if [[ $(is_app_available $os_installer) -eq 0 ]]; then
        $print "⚓ $os_installer found at: $(which $os_installer) "
    else
        local failure="❌ $os_installer was not found! This script may have been incorrectly executed."
        $print "$failure"
        failed_executions+=("$failure")
        terminate_script 1
    fi

    # update apt-get
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y update)
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y upgrade)    
}
set_installer_access

# Install Homebrew, set as the alternate installer
installer="brew"
function install_homebrew() {
    $print "${highlight}"
    $print "🐠 Installing Homebrew and adding to Shell Paths"
    $print "${reset_format}"

    if [[ $(is_app_available brew) -eq 0 ]]; then
        $print "⚓🍺 Homebrew installed! found at: $(which brew) "
    else
        $print "🚧 Installing 🍺 Homebrew."
        # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
        # subshell without elevated access?
        (NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
    fi

    # Check installation status
    if [[ $(is_app_available "brew") -eq 0 ]]; then
        $print "✅ brew installation successful!"
    else
        local failure="❌ brew installation failed!"
        $print "$failure"
        failed_executions+=("$failure")
        terminate_script 1
    fi

    # update, brew should be available 
    $print "${highlight}"
    $print "⬆️  Updating homebrew and its packages"
    $print "${reset_format}"
    ($installer update)
    ($installer upgrade)
}
install_homebrew

# ========== non-critical ========== #
# Language and tooling
install_application "git" "apt-get"
install_application "python3" "apt-get"
# install_application "build-essential" "apt-get" # note this is special install
install_application "gcc" "apt-get"
install_application "clang" "apt-get"
install_application "valgrind" "apt-get"

# Productivity
install_application "tmux" "apt-get"
install_application "neovim" "apt-get" 

# TODO add a third param (that takes in an array of strings)
# to check for proper installation rather than the initial package name. EG neovim->nvim and build-essential

# zsh-autosuggestions