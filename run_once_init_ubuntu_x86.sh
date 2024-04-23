#!/bin/bash

function get_os_info() {
    os_name=$(uname -s)
    kernel_name=$(uname -r)
    architecture=$(uname -m)

    if [[ "$os_name" == "Linux" ]]; then
    # Try using /etc/os-release (more reliable for distro info)
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release  # Load os release variables
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
        echo "🐠 Operating System: $os_name"
        echo "🐠 Kernel Name: $kernel_name"
        echo "🐠 Architecture: $architecture"
        echo "🐠 Linux Distribution: $linux_distro"
    else
        echo "⚓ Incorrect params, skipping Ubuntu x64 Initalization"
        exit 0
    fi
}
get_os_info

echo "🐠 Running Ubuntu x86 Initalization Script"

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
        $print "🐠 Run once base install script complete. Yipee! Restart/Logout to finish setup."
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
# ========== utilities ========== #

# =============== actual executed scripts ===============
# setup privilege access
privileged_access="sudo"
installer="DEBIAN_FRONTEND=noninteractive apt-get -y"
function set_access(){

    # I was initially running su vs sudo but running sudo on all is probably fine, will need to change when running for powershell
    privileged_access="sudo"
    $print "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    $print "${highlight}"
    $print "**WARNING:** This script will bypass all install prompt and will install dependancies automatically"
    $print "**WARNING:** Prompting you with sudo access, this is to pass sudo access to specific install commands"
    $print "${reset_format}"
    $privileged_access echo "** granted ${privileged_access} privilege **"

    # set the installer and check access
    $print "⚓  installer set to: ${installer} updating installer...\n"

    if [[ $(is_app_available "apt-get") -eq 0 ]]; then
        $print "⚓ apt-get found at: $(which apt-get) "
    else
        $print "🚧 installing apt"
    fi

    "$privileged_access apt update"
    "$privileged_access apt upgrade"
}
set_access
