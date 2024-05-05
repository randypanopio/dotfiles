#!/bin/bash

function get_os_info() {
    os_name=$(uname -s)
    kernel_name=$(uname -r)
    architecture=$(uname -m)

    if [[ "$os_name" == "Linux" ]]; then
    # Try using /etc/os-release (more reliable for distro info)
        if [[ -f /etc/os-release ]]; then
            # shellcheck disable=SC1091
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

# ========== formatting ========== #
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
function print_func() {
    message=${1}
    # shellcheck disable=SC2059
    printf "${message}\n"
}

# highlight text: ${highlight} <text> ${reset_format} 

# ========== global variables ========== #
privileged_access="sudo"
config_file="$HOME/.rpanopio_config.yaml"

# ========== utilities ========== #
declare -a failed_executions
function terminate_script(){
    exit_code=${1}
    if [[ ${#failed_executions[@]} -gt 0 ]]; then
        print_func "\n${warn_highlight} The following execution steps failed:${reset_format}\n"
        for step in "${failed_executions[@]}"; do
            print_func "- $step"
        done
    else 
        print_func "✅ zero issues found"
    fi

    if [[ $exit_code == 1 ]]; then
        print_func "\n${warn_highlight}⚠️ Script was terminated early!${reset_format}\n"
    else
        print_func "\n${highlight}⚓ Run once base install script complete. Yipee! Restart/Logout to finish setup.${reset_format}\n"
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

# cli applications (Aka contains keyword we can check)
function install_cli_application() {
    local application=${1-}
    local installer_arg=${2-}
    local aliases=${3}

    local fully_installed=true
    local has_aliases=false
    # check if it is already installed
    # shellcheck disable=SC2199
    if [[ -z "${aliases[@]}" ]]; then
        # directly check the passed application name if it is available
        if is_app_available "$application"; then
            print_func "\n${highlight}⚓ $application installed! found at: $(which "$application")${reset_format}\n"
            fully_installed=true
        else
            fully_installed=false
        fi
        has_aliases=false
    else
        has_aliases=true
        # check if aliases are ALL available
        for alias in "${aliases[@]}"
        do
            # immediately break if any alias is missing, so install package
            if ! is_app_available "$alias"; then
                fully_installed=false
                break
            fi
        done
        print_func "\n${highlight}⚓ $application (and it's aliases) are installed!${reset_format}\n"
    fi

    # Install application if any are found missing
    if [[ $fully_installed == false ]]; then
        print_func "\n${highlight}🚧 Installing $application${reset_format}\n"

        # format the correct install command and update command respectively (and if elevated)
        local command=""
        if [[ $installer_arg == "brew" ]]; then
            command="brew install --quiet $application"
        elif [[ $installer_arg == "apt-get" ]]; then
            command="$privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y install $application"
        elif [[ $installer_arg == "apt" ]]; then
            command="$privileged_access DEBIAN_FRONTEND=noninteractive apt -y install $application"                        
        else
            local failure="❌ tried to install $application with $installer_arg, which is not a  supported installer!"
            print_func "$failure"
            failed_executions+=("$failure")
            return 1
        fi
        print_func "⚓ formatted command: [$command]"
        ($command)

        # validate if installation was succesful
        if [[ $has_aliases == true ]]; then
            # check if aliases are ALL available post installation
            for alias in "${aliases[@]}"
            do
                if ! is_app_available "$alias"; then 
                    local failure="❌ $application installation failed! Unable to validate alias: $alias as installed"
                    print_func "$failure"
                    failed_executions+=("$failure")
                    return 1
                fi
            done
        else
            if is_app_available "$application"; then
                print_func "✅ $application installation successful!"
            else
                local failure="❌ $application installation failed! Unable to validate post installation"
                print_func "$failure"
                failed_executions+=("$failure")
                return 1
            fi
        fi
    fi

    # Update application(s)
    print_func "⬆️  Updating ${highlight}${application}${reset_format}\n"
    if [[ $installer_arg == "brew" ]]; then
        # shellcheck disable=SC2086
        (brew upgrade --quiet $application)
    elif [[ $installer_arg == "apt-get" ]]; then
        # shellcheck disable=SC2086
        ($privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y upgrade $application)
    elif [[ $installer_arg == "apt" ]]; then
        # shellcheck disable=SC2086
        ($privileged_access DEBIAN_FRONTEND=noninteractive apt -y upgrade $application)                      
    else
        local failure="❌ tried to update $application with $installer_arg, which is not a  supported installer!"
        print_func "$failure"
        failed_executions+=("$failure")
        return 1
    fi

    print_func "\n${highlight}⚓ $application install and upgrade complete.${reset_format}\n=========="
}

# non cli apps (contains no installation validation)
function install_application() {
    local application=${1-}
    local installer_arg=${2-}

    print_func "\n${highlight}🚧 Installing $application${reset_format}\n"

    # Install application directly (and it should update too)
    local command=""
    if [[ $installer_arg == "brew" ]]; then
        command="brew install --quiet $application"
    elif [[ $installer_arg == "apt-get" ]]; then
        command="$privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y install $application"
    elif [[ $installer_arg == "apt" ]]; then
        command="$privileged_access DEBIAN_FRONTEND=noninteractive apt -y install $application"                        
    else
        local failure="❌ tried to install $application with $installer_arg, which is not a  supported installer!"
        print_func "$failure"
        failed_executions+=("$failure")
        return 1
    fi
    print_func "⚓ formatted command: [$command]"
    ($command)

    print_func "\n${highlight}⚓ $application install application complete.${reset_format}\n=========="
}


# ========== installs ========== #
# Requests sudo perms from the user, and updates package manager
function set_installer_access(){
    privileged_access="sudo"
    print_func "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    print_func "\n${highlight}**WARNING:** This script will bypass all install prompt and will install dependancies automatically\n**WARNING:** Prompting you with sudo access, this is to pass sudo access to specific install commands${reset_format}\n"
    $privileged_access echo "** granted ${privileged_access} privilege **"

    # set apt-get and check access
    local os_installer="apt-get"
    if is_app_available "$os_installer"; then
        print_func "⚓ $os_installer found at: $(which $os_installer) "
    else
        local failure="❌ $os_installer was not found! This script may have been incorrectly executed."
        print_func "$failure"
        failed_executions+=("$failure")
        terminate_script 1
    fi

    # update apt-get
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y update)
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt-get -y upgrade)
    # update apt
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt -y update)
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt -y upgrade)
    print_func "\n${highlight}🐠 set_installer_access complete.${reset_format}\n=========="
}

# Install Homebrew, set as the alternate installer
function install_homebrew() {
    print_func "\n${highlight}🐠 Installing Homebrew and adding to Shell Paths${reset_format}\n"

    if is_app_available "brew"; then
        print_func "⚓🍺 Homebrew installed! found at: $(which brew) "
    else
        print_func "🚧 Installing 🍺 Homebrew."
        # https://github.com/Homebrew/install/#install-homebrew-on-macos-or-linux
        # subshell without elevated access?
        (NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
    fi

    # Check installation status
    if is_app_available "brew"; then
        print_func "✅ brew installation successful and is now available for use!"
    else
        local failure="❌ brew installation failed!"
        print_func "$failure"
        failed_executions+=("$failure")
        terminate_script 1
    fi

    # update, brew should be available 
    print_func "\n${highlight}⬆️  Updating homebrew and its packages${reset_format}\n"
    (brew update)
    (brew upgrade)

    print_func "\n${highlight}🐠 install_homebrew complete.${reset_format}\n=========="
}

# install zsh and set as default shell
function install_zsh(){
    print_func "\n${highlight}🐠 Installing and setting default shell to Zsh${reset_format}\n"

    # check and install zsh
    if is_app_available "zsh"; then
        print_func "⚓ zsh installed! found at: $(which zsh) "
    else
        print_func "🚧 Installing zsh on Ubuntu..."
        install_cli_application "zsh" "apt"
    fi

    # just install the zsh plugins, I don't even know why I bothered writing install checks
    install_application "zsh-autosuggestions" "apt"
    install_application "zsh-syntax-highlighting" "apt"

    # Do another installation check
    if is_app_available "zsh"; then
        print_func "✅ zsh installation successful!"
    else
        local failure="❌ zsh installation failed"
        print_func "$failure"
        failed_executions+=("$failure")
        terminate_script 1
    fi

    # Check if zsh is the current default shell
    print_func "⚓ Checking current shell: $SHELL, zsh shell: $(which zsh)"
    if [[ ${SHELL##*/} == "zsh" ]]; then
        print_func "⚓ zsh is already your default shell."
    else
        print_func "🚧 changing default shell to zsh."
        $privileged_access chsh -s "$(which zsh)"
        
        # Verify the change, I dont think I can get this to easily work..
        # if [[ "$current_shell" == $(which $new_shell) ]]; then
        #     print_func "✅ $new_shell has been set as your default shell successfully."
        # else
        #     print_func "${warn_highlight}"
        #     print_func "⚠️  An error occurred while setting $new_shell as the default shell! May need to manually change default shell to $new_shell."
        #     print_func "${reset_format}"
        # fi
        print_func "${highlight}"
        print_func "⚠️ Skipping validation of setting zsh as the default shell! May need to manually change default shell to zsh."
        print_func "${reset_format}"
    fi

    # update zsh
    print_func "\n${highlight}⬆️  Updating zsh${reset_format}\n"
    ($privileged_access DEBIAN_FRONTEND=noninteractive apt -y upgrade zsh)
    print_func "\n${highlight}🐠 install_zsh complete.${reset_format}\n=========="
}

# install oh-my-zsh
function install_ohmyzsh(){
    print_func "\n${highlight}🐠 Installing oh-my-zsh${reset_format}\n"

    # check if zsh is avail    
    if ! is_app_available "zsh"; then
        local failure="⚠️  Zsh not found! Unable to install oh-my-zsh."
        print_func "$failure continuing with script"
        failed_executions+=("$failure")
        return 1
    fi

    zsh_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    oh_my_zsh_installer="sh -c $(curl -fsSL $zsh_url)" # taken from https://ohmyz.sh/#install seems platform agnostic
    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_func "⚓ ${highlight} Oh My Zsh ${reset_format} already installed."
    else
        # Proceed with installation
        print_func "Installing Oh My Zsh remote script: $zsh_url"
        (eval "$oh_my_zsh_installer")  # Execute installation in a subshell
        # Do another installation check
        if is_app_available "omz"; then
            print_func "✅ oh-my-zsh installation successful!"
        else
            local failure="❌ oh-my-zsh installation failed"
            print_func "$failure"
            failed_executions+=("$failure")
            return 1        
        fi
    fi
    # update
    print_func "\n${highlight}⬆️  Updating oh-my-zsh${reset_format}\n"
    ("$ZSH/tools/upgrade.sh")

    print_func "\n${highlight}🐠 install_ohmyzsh complete.${reset_format}\n=========="   
}

# Install remaining applications
function install_config_applications () {
    local file="$1"
    print_func "\n${highlight}🐠 Parsing: [$config_file], for additional application installs${reset_format}\n"

    # parse config file manually
    local in_program=false
    local package=""
    local installer=""
    while IFS= read -r line; do
        # Skip lines that are comments or not within the "cli-programs" section
        if [[ $line =~ ^\s*# || $line =~ ^\s*[^cli-programs]*: ]]; then
            continue
        fi

        # Check if we are in the cli-programs section
        if [[ $line == "cli-programs:" ]]; then
            in_program=true
            continue
        fi

        # NOTE this assumes that the order of these arguements are in this specific order
        # and that these exist in the yaml file, probably fine since that should be 
        # documented in the yaml file itself.

        # WARNING TODO BUGFIX - this doesn't actually work, it will start parsing again so long as it matches the correct 3 stage format, which is probably fine, but it can cause issues when another object/config will have the same 3 stage format  
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
                    # shellcheck disable=SC2004
                    trimmed_aliases[$i]="${trimmed_aliases[$i]//[[:space:]]/}"
                done
                
                # pass application install arg to install func
                install_cli_application "$package" "$installer" "${trimmed_aliases[@]}"
            fi
        fi
    done < "$file"
    print_func "\n${highlight}🐠 install_config_applications complete.${reset_format}\n=========="
}

# blindly install remote/custom install commands, should require at least brew and git
function config_blind_installs () {
    local file="$1"
    print_func "\n${highlight}🐠 Parsing: [$config_file], for additional blind arbitrary installations. AKA custom external scripts${reset_format}\n"

    # parse config file manually
    local in_program=false
    local package=""
    local installer=""
    while IFS= read -r line; do
        # Skip lines that are comments or not within the "blind-installs" section
        if [[ $line =~ ^\s*# || $line =~ ^\s*[^blind-installs]*: ]]; then
            continue
        fi

        # Check if we are in the blind-installs section
        if [[ $line == "blind-installs:" ]]; then
            in_program=true
            continue
        fi

        # NOTE this assumes that the order of these arguements are in this specific order
        # and that these exist in the yaml file, probably fine since that should be 
        # documented in the yaml file itself.

        # WARNING TODO BUGFIX - SEE install_config_applications issue
        if [[ $in_program == true && $line == *"command"* ]]; then
            # get command value 
            command=$(echo "$line" | awk -F": " '{print $2}')
            print_func "🌵blind-install🌵 command: [$command]"
            ($command)
        fi
    done < "$file"
    print_func "\n${highlight}🐠 config_blind_installs complete.${reset_format}\n=========="
}

# main functions
set_installer_access # prompts sudo access and validates default package manager
install_homebrew
install_zsh
install_ohmyzsh
install_config_applications "$config_file"
config_blind_installs "$config_file"

terminate_script 0