#!/bin/bash
function get_os_info() {
    os_name=$(uname -s)
    kernel_name=$(uname -r)
    architecture=$(uname -m)

    if [[ "$os_name" == "Linux" && "$architecture" == *"ARM"* ]]; then
        echo "🐠 Operating System: $os_name"
        echo "🐠 Kernel Name: $kernel_name"
        echo "🐠 Architecture: $architecture"
    else
        echo "⚓ Incorrect params, skipping Darwin Arm Initalization"
        exit 0
    fi
}
get_os_info
echo "🐠 Running Darwin ARM Initalization Script"

# MACO SCRIPT TODO add xcode