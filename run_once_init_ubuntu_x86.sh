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
    local aliases=${3}

    # check if aliases is passed, use that for installation validation
    # TODO add alias checking as well
    # for element in "${aliases[@]}"
    # do
    #     echo "alias: $element"
    # done

    # check if it is already installed
    if is_app_available "$application"; then
        $print "${highlight}"
        $print "⚓ $application installed! found at: $(which "$application")"
        $print "${reset_format}"
    else
        $print "${highlight}"
        $print "🐠 Installing $application"
        $print "${reset_format}"

        # format the correct install command and update command respectively (and if elevated)
        local command=""
        if [[ $installer_arg == "$installer" ]]; then 
            command="brew install --quiet $application"
        elif [[ $installer_arg == "$os_installer" ]]; then
            # default to os_installer 
            command="$privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y install $application"            
        else
            local failure="❌ tried to install $application with $installer_arg, which is supported installer!"
            $print "$failure"
            failed_executions+=("$failure")
            return 1
        fi
        $print "⚓ formatted command: [$command]"
        ($command)

        # validate if application installed succesfully
        if is_app_available "$application"; then
            $print "✅ $application installation successful!"
        else
            local failure="❌ $application installation failed! Unable to validate post installation"
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
    $print "⚓${highlight} $application install and upgrade complete.${reset_format}\n"

    # TODO do i update alias or the package? alias probably?
}

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

    if is_app_available "$os_installer"; then
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

# Install Homebrew, set as the alternate installer
installer="brew"
function install_homebrew() {
    $print "${highlight}"
    $print "🐠 Installing Homebrew and adding to Shell Paths"
    $print "${reset_format}"

    if is_app_available "brew"; then
        $print "⚓🍺 Homebrew installed! found at: $(which brew) "
    else
        $print "🚧 Installing 🍺 Homebrew."
        # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
        # subshell without elevated access?
        (NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
    fi

    # Check installation status
    if is_app_available "brew"; then
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

# install zsh and set as default shell
#TODO 

# install oh-my-zsh
#TODO

config_file="$HOME/.rpanopio_config.yaml"
# Install remaining applications
# Maybe TODO refactor to generic parser 
function install_config_applications () {
    local file="$1"
    $print "${highlight}"
    $print "🐠 Parsing: [$config_file], for additional application installs"
    $print "${reset_format}"

    # parse config file manually
    local in_program=false
    local package=""
    local installer=""
    while IFS= read -r line; do
        # Skip lines that are comments or not within the "programs" section
        if [[ $line =~ ^\s*# || $line =~ ^\s*[^programs]*: ]]; then
            continue
        fi

        # Check if we are in the programs section
        if [[ $line == "programs:" ]]; then
            in_program=true
            continue
        fi

        # NOTE this assumes that the order of these arguements are in this specific order
        # and that these exist in the yaml file, probably fine since that should be 
        # documented in the yaml file itself.

        if [[ $in_program == true && $line == *"package"* ]]; then
            # get package value 
            package=$(echo "$line" | awk -F": " '{print $2}')
        fi
        if [[ $in_program == true && $line == *"installer"* ]]; then
            # get installer value 
            installer=$(echo "$line" | awk -F": " '{print $2}')
        fi
        if [[ $in_program == true && $line == *"aliases"* ]]; then
            # Get aliases value
            alias_value=$(echo "$line" | awk -F": " '{print $2}')
            # trim brackets
            alias_value=$(echo "$alias_value" | tr -d '[]') 

            # Check if the alias value is empty or whitespace-only
            if [[ -z "${alias_value// }" ]]; then
                # call without passing 3rd array arg
                install_application "$package" "$installer"
            else
                # Split using comma as delimiter, allowing optional spaces around the comma
                IFS=',' read -r -a trimmed_aliases <<< "${alias_value//,/ ,}"

                # Remove all whitespace from each element using parameter expansion
                for i in "${!trimmed_aliases[@]}"; do
                    # Remove all whitespace
                    trimmed_aliases[$i]="${trimmed_aliases[$i]//[[:space:]]/}"
                done
                
                # pass application install arg to install func
                install_application "$package" "$installer" "${trimmed_aliases[@]}"
            fi
        fi
    done < "$file"
}


# zsh-autosuggestions

# wrap up and close 


# execute functions
set_installer_access # prompts sudo access and validates default package manager
# install_homebrew
# install_zsh
# install_ohmyzsh
install_config_applications "$config_file"
echo "cat config file"
cat "$config_file"

terminate_script 0