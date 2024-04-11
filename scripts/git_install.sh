#!/bin/bash
echo "\n"
echo "🐠 executing git_install..."

# formatting stuffs
highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
# highlight text: ${highlight} <text> ${reset_format} 

function install_git() {
    os_name=$(uname)
    $print "\n${highlight}"
    $print "🐠 Installing git"
    $print "${reset_format}"
    
    if command -v git &> /dev/null; then
        $print "⚓ git installed! found at: $(which git) "
    else
        $print "🚧 installing git"
    fi
}
install_git

# sets up additional git settings
exit 0