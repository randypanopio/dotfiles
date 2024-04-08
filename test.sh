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
function set_privileged_access(){
    # I was initially running su vs sudo but running sudo on all is probably fine, will need to change when running for powershell
    privileged_access="sudo"
    $print "using ${highlight} ${privileged_access} ${reset_format} for elevated privilege"

    $print "\n${highlight}"
    $print "**WARNING:** Prompting you with sudo access, this is to pass sudo access to specific install commands"
    $print "${reset_format}"
    $privileged_access echo "** granted ${privileged_access} privilege **"
}



# run another script
bash './scripts/brew_install.sh'