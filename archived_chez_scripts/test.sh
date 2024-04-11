#!/bin/bash
echo "🐠 testing one func at a time"

highlight="\e[34m" # red
warn_highlight="\e[31m" # blue
reset_format="\e[0m"
print="echo -e"
os_name="Linux"
os_distro="ubuntu"
os_installer="apt-get"


declare -a failed_executions
function terminate_script(){
    exit_code=${1}
    if [[ $($exit_code) -eq 0 ]]; then
        $print "⚠️  Terminating the script early!"
    fi

    if [[ ${#failed_executions[@]} -gt 0 ]]; then
        $print "The following execution steps failed:"
        for step in "${failed_executions[@]}"; do
            $print "- $step"
        done
    fi
    exit $exit_code
}

function foo() {
local failure="❌ brew installation failed. halting script..."
$print $failure
failed_executions+=$failure
terminate_script 1
}
foo

terminate_script 0