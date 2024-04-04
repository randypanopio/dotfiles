#!/bin/bash
echo "🐠 testing one func at a time"

highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
os_name="Linux"
os_distro="ubuntu"
os_installer="apt-get"

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

# Install ZSH - base shell for everything
$print "\n${highlight}"
$print "🐠 Installing and setting default shell to Zsh"
$print "${reset_format}"
# safe to assume zsh is installed on a macos platform probably...
function install_zsh(){

    # Check installation status
    if which zsh >/dev/null 2>&1; then
        $print "✅ zsh installation successful!"
    else
        $print "❌ zsh installation failed. exiting..."
        exit 1
    fi

    # Check if zsh is the current default shell
    new_shell="bash"
    current_shell=$(echo $SHELL)
    $print "changing default shell to $new_shell."
    $privileged_access chsh -s $(which $new_shell)
    
    # Verify the change
    temporary_shell="$(which sh)"  # Or any other shell besides the current one

    current_user=$(whoami)
    user_entry=$(grep "^$current_user:" /etc/passwd)
    shell_path=${user_entry##*:}

    echo $shell_path
    # output=$($temporary_shell -c "echo $SHELL")
    $print "current shell: $current_shell, $new_shell installation: $(which $new_shell), subshell output: $shell_path"
    if [[ "$shell_path" == $(which $new_shell) ]]; then
        $print "✅ $new_shell has been set as your default shell successfully."
    else
        $print "${warn_highlight}"
        $print "⚠️  An error occurred while setting $new_shell as the default shell! May need to manually change default shell to $new_shell."
        $print "${reset_format}"
    fi
}
install_zsh