#
# Copyright (c) 2022 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

#!/bin/bash

hooks="applypatch-msg pre-applypatch post-applypatch pre-commit prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge pre-receive update post-receive post-update pre-auto-gc post-rewrite pre-push"

function show_usage()
{
    echo "usage: hookmgr.sh <add | del> <githook> <shell command>"
    echo
    echo
    echo "This script adds or removes a command to/from"
    echo "a specified git hook. Used to automatically"
    echo "handle hooks in a project."
    exit
}

function start()
{
    action=$1
    hook_name=$2
    command=$3

    if ! echo $hooks | grep "$hook_name" &> /dev/null; then
        echo "hookmgr.sh: Specified hook does not exist"
        exit
    fi

    hook_path="./.git/hooks/$hook_name"
    hook_command="nohup $command > out/$hook_name.log &"

    if [ ! -e "$hook_path" ]; then
        if [ "$action" == "del" ]; then exit; fi
        echo '#!/bin/sh' >> "$hook_path"
        echo "" >> "$hook_path"
        chmod u+x "$hook_path"
    fi

    if [ "$action" == "add" ]; then
        if cat "$hook_path" | grep -F "$hook_command" >/dev/null; then
            echo "hookmgr.sh: Your command already exists in the $hook_name hook"
        else
            echo "$hook_command" >> "$hook_path"
            echo "" >> "$hook_path"
            echo "hookmgr.sh: Your command has been added to the $hook_name hook"
        fi
    fi

    if [ "$action" == "del" ]; then
        cat "$hook_path" | grep -vF "$hook_command" > "$hook_path.tmp"

        if diff "$hook_path" "$hook_path.tmp" >/dev/null; then
            rm "$hook_path.tmp"
            echo "hookmgr.sh: Your command has already been removed from the $hook_name hook"
        else
            mv "$hook_path.tmp" "$hook_path"
            echo "hookmgr.sh: Your command has been removed from the $hook_name hook"
        fi
    fi
}

if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" != "add" ] && [ "$1" != "del" ]; then
    show_usage
elif [ "$1" == "add" ] || [ "$1" == "del" ]; then
    start "$1" "$2" "$3"
fi