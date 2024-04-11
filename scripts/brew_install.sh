#!/bin/bash
echo "\n"
echo "🐠 executing brew_install..."

# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

function install_homebrew() {
    os_name=$(uname)
    $print "\n${highlight}"
    $print "🐠 Installing Homebrew and adding to Shell Paths"
    $print "${reset_format}"

    brew_required="true"

    if command -v brew &> /dev/null; then
        $print "⚓🍺 Homebrew installed! found at: $(which brew) "
    else
        # Install platform specific
        if [[ $os_name == "Linux" ]]; then
            cat_os_release=$(cat /etc/os-release)
            if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
                if [[ $(uname -m) =~ "aarch64" ]]; then
                    $print "homebrew is not supported on aarch64 architecture 🥲"
                fi
                brew_required="false"
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
        if command -v brew &> /dev/null; then
            $print "✅ brew installation successful!"
        else
            $print "❌ brew installation failed. exiting..."
            exit 1
        fi

        # update brew
        $print "\n${highlight}"
        $print "⬆️  Updating homebrew and its packages"
        $print "${reset_format}"
        (brew update)
        (brew upgrade)
    fi
}
install_homebrew
exit 0