#!/bin/bash
exit 0
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
echo "🐠 Running Ubuntu x64 Initalization Script"