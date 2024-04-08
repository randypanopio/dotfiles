#!/bin/bash
# installs my primary language and base build tools
echo "🐠 executing language_install..."

# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 
os_name=$(uname)

# Python and Tooling
function install_python3(){
    $print "\n${highlight}"
    $print "🐠 Installing Python 3 on $os_name"
    $print "${reset_format}"

    # validate if installed and already in path
    if ! command -v python3 &> /dev/null; then
        $print "\n${highlight}"
        $print "🚧 Python3 was not found in PATH. It might exist eleswhere, but installing and setting to path anyways"
        $print "${reset_format}"

        # Install platform specific
        if [[ $os_name == "Linux" ]]; then
            cat_os_release=$(cat /etc/os-release)
            if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
                $print "ℹ️ Installing Python3 on $os_name"
                sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3
            # elif [[ $cat_os_release =~ "ID=debian" ]]; then
                # TODO buildme
            fi
        elif [[ $os_name == "Darwin" ]]; then
            # we use brew, but should be already avail.
            $print "ℹ️ Installing Python3 on $os_name"
            brew install python3
        fi
    fi

    # Do another installation check
    if which python3 >/dev/null 2>&1; then
        $print "✅ Python3 installation successful!"
    else
        $print "${warn_highlight}"
        $print "❌ Python3 installation failed. exiting..."
        $print "${reset_format}"
        exit 1
    fi

    # Upgrade Python3
    $print "⬆️  Updating ${highlight} Python3 ${reset_format}"
    if [[ $os_name == "Linux" ]]; then
        cat_os_release=$(cat /etc/os-release)
        if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get -y install --only-upgrade Python3
        # elif [[ $cat_os_release =~ "ID=debian" ]]; then
            # TODO buildm
        fi
    elif [[ $os_name == "Darwin" ]]; then
        # we use brew, but should be already avail.
        brew upgrade python3
    fi    

    # Check if Python is aliased with py on zhrc
    if [[ $os_name == "Linux" || $os_name == "Darwin" ]]; then
        # Check if 'py' is already aliased to 'python3'
        alias_line=$(grep -E "^alias\s+py=python3\s*$" ~/.zshrc)

        if [[ -z "$alias_line" ]]; then
            # 'py' is not currently aliased to 'python3'
            $print "ℹ️ Adding alias py=python3 to ~/.zshrc"
            echo "alias py=python3" >> ~/.zshrc
            # source ~/.zshrc  # Reload the ZSH configuration
        else
            $print "ℹ️ py is already aliased to python3 in your ~/.zshrc"
        fi
    fi
}
install_python3

# C and C++ Tooling
# GCC build-essential tools (C++ and C)
# clang
# make
function install_build_essentials() {
    $print "\n${highlight}"
    $print "🐠 Installing Build Essentials on $os_name"
    $print "${reset_format}"
}
install_build_essentials

# Java and Tooling


# C# and Tooling


# Javascript and Tooling

# Node.JS

# npm

exit 0