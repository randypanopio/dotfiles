#!/bin/bash
echo "🐠 executing zsh_install..."

# formatting stuffs
highlight="\e[34m" # red
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

# Install ZSH - base shell for everything

# safe to assume zsh is installed on a macos platform probably...
function install_zsh(){
    os_name=$(uname)
    $print "\n${highlight}"
    $print "🐠 Installing and setting default shell to Zsh"
    $print "${reset_format}"

    if ! command -v zsh &> /dev/null; then
    # if ! which zsh >/dev/null 2>&1; then
        $print "⚓ zsh installed! found at: $(which zsh) "
    else
        # Install platform specific
        if [[ $os_name == "Linux" ]]; then
            cat_os_release=$(cat /etc/os-release)
            if [[ $cat_os_release =~ "ID=ubuntu" ]]; then
                $print "🚧 Installing zsh on Ubuntu..."
                sudo DEBIAN_FRONTEND=noninteractive apt-get -y install zsh
            fi
        elif [[ $os_name == "Darwin" ]]; then
            $print "🚧 Installing zsh on MacOS... Though that really shouldn't have happened!"
            (brew install zsh)
        fi
    fi

    # Do another installation check
    if ! command -v zsh &> /dev/null; then
        $print "✅ zsh installation successful!"
    else
        $print "❌ zsh installation failed. exiting..."
        exit 1
    fi

    # Check if zsh is the current default shell
    new_shell="zsh"
    new_shell_loc=$(which zsh)
    current_shell="echo $SHELL"

    $print "current shell: ${current_shell}, zsh shell: ${new_shell_loc}"
    if [[ $current_shell == "${new_shell_loc}" ]]; then
        $print "⚓ zsh is already your default shell."
    else
        $print "changing default shell to $new_shell."
        sudo chsh -s "$(which $new_shell)"
        
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

exit 0