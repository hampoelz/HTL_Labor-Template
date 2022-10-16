#
# Copyright (c) 2022 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

#!/bin/bash

timeout=120

post_commit() (
    latexmk -g --interaction=nonstopmode
)

post_push() {
    counter=0
    branch=$(git branch --show-current)
    while sleep 0.5; do
        if [ "$(git log --oneline origin/$branch..$branch)" == "" ] &>/dev/null; then
            post_commit
            break
        else
            counter=$((counter+1))
        fi

        if [ $counter -ge $timeout ]; then break; fi
    done
}

if [ "$1" == "--post_push" ]; then
    post_push
elif [ "$1" == "--post_commit" ]; then
    post_commit
else
    exit 1
fi