#
# Copyright (c) 2022 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

#!/bin/bash

# minimum required git version: v2.22.0

gh_repo="hampoelz/HTL_LaTeX-Template"
remote_branch="main"

remote="https://github.com/$gh_repo"

update_branch="tmp/template"

commit_msg="chore: :twisted_rightwards_arrows: Merge changes from template"
commit_descr="Merged from $remote/tree/$remote_branch"

# file storing the commit SHAs picked from template
tplver_file=".git/tplver"

#file storing the current (not update) branch
currbr_file=".git/currbr"

# commits ignored by cherry-pick (seperate with space)
ignore_SHAs="9fa9fd2"


hookmgr_path="scripts/hookmgr.sh"
rebuild_script="scripts/hooks/rebuild.sh"

script_path=".git/~update.sh"
script_url="https://raw.githubusercontent.com/$gh_repo/$remote_branch/scripts/update.sh"

if [ -e "$currbr_file" ]; then branch=$(head -n 1 "$currbr_file"); fi

function show_usage()
{
    echo "usage: update.sh (--abort)"
    echo
    echo
    echo "This script updates the current repository"
    echo "to the state of the template repository at:"
    echo "$remote"
    echo "Changes are cherry-picked and merged"
    exit
}

function pull_script()
{
    function realpath() { echo $(cd $(dirname "$1"); pwd)/$(basename "$1"); }
    
    script_path="$(realpath $1)"
    if [ "$(realpath $0)" == "$script_path" ]; then return 0; fi
    if [ -d "$script_path" ]; then
        echo Pull latest update script ...
        curl -sL "$script_url" -o "$script_path"
        bash "$script_path" $2
        exit
    fi
}

function check_internet()
{
    timeout 1 ping github.com -c 1 &> /dev/null || {
        echo
        echo "========================================================"
        echo "              Unable to connect to github!              "
        echo "          Please check your internet connection         "
        echo "========================================================"
        echo
        exit
    }
}

function check_git()
{
    git rev-parse --is-inside-work-tree &> /dev/null || {
        echo
        echo "========================================================"
        echo "     This script can only be used inside a git repo     "
        echo "========================================================"
        echo
        exit
    }
}

function check_git_version()
{
    git_version="$(git --version | cut -d " " -f 3)"

    if [ $(echo "$git_version 2.22.0" | tr ' ' '\n' | sort -V | head -n 1) != "2.22.0" ]; then
        echo
        echo "========================================================"
        echo "          Please update your Git installation,          "
        echo "          at least version 2.22.0 is required!          "
        echo
        echo "          Your installed version:                       "
        echo "              $git_version                              "
        echo "========================================================"
        echo
        
        read -r -p "Would you like to continue anyway? The script could fail and cause issues. (y/N) " git_version_ignore
        echo
        if [ "${git_version_ignore^^}" != "Y" ]; then exit; fi
    fi
}

function check_unmerged()
{
    git update-index --refresh
    git diff --quiet --exit-code --name-only --diff-filter=U || {
        echo
        echo "========================================================"
        echo "   Please resolve conflicts and run the task again      "
        echo "    or select the abort option when starting the task   "
        echo "========================================================"
        echo
        exit
    }
}

function check_untracked()
{
    git update-index --refresh
    git diff-index --quiet HEAD -- || {
        echo
        echo "========================================================"
        echo "       There are untracked changes, please commit       "
        echo "        your changes and run the task again             "
        echo "========================================================"
        echo
        exit
    }
}

function check_merge()
{
    git merge HEAD &> /dev/null || {
        echo
        echo "========================================================"
        echo "   Sorry, another git workflow is already in progress   "
        echo "========================================================"
        echo
        exit
    }
}

# check if update-branch exists and go ahead else execute parameter
function check_branch()
{
    git rev-parse --verify $update_branch &> /dev/null || "$@"
}

function init_empty()
{
    git rev-parse --verify HEAD &> /dev/null || git commit --allow-empty -m "Initial commit"
}

function cleanup()
{
    echo -------- cleanup ---------
    if [ -e "$tplver_file" ]; then rm "$tplver_file"; fi
    if [ -e "$currbr_file" ]; then rm "$currbr_file"; fi
    git checkout $branch
    git branch -D $update_branch
    git remote remove template
    exit
}

function abort()
{
    check_branch exit
    echo --- abort cherry-pick ----
    git cherry-pick --abort
    cleanup
    exit
}

function start_merge()
{
    check_unmerged

    echo ------ merge update ------
    # read picked commit list
    picked_SHAs=$(head -n 1 "$tplver_file")

    # merge update and commit
    git checkout $branch
    git merge -X theirs --squash $update_branch
    git commit -m "$commit_msg" -m "$commit_descr" -m "(picked commits: $picked_SHAs)"

    echo
    echo "========================================================"
    echo "             Update was successfully merged             "
    echo "========================================================"
    echo

    # add rebuild hooks
    if [ -e "$hookmgr_path" ] && [ -e "$rebuild_script" ]; then
        /bin/bash "$hookmgr_path" add pre-push "bash $rebuild_script --post_push" > /dev/null
        /bin/bash "$hookmgr_path" add post-commit "bash $rebuild_script --post_commit" > /dev/null
    fi

    cleanup
}

function start_update()
{
    # check if there is a git workflow in progress or there are untracked changes else create update-branch
    check_merge
    check_untracked

    # get current branch
    git branch --show-current > "$currbr_file"
    branch=$(head -n 1 "$currbr_file")

    echo -- create update branch --
    git checkout -b $update_branch

    # add template repo if not already added
    git ls-remote --exit-code template &> /dev/null || git remote add template $remote
    git fetch --quiet template

    echo ----- check updates ------
    # read last picked commit - if not found, use branch
    lastpick=""
    if [ -e "$tplver_file" ]; then lastpick=$(head -n 1 "$tplver_file"); fi
    if [ "$lastpick" == "" ]; then lastpick=$branch; fi

    # get non-equivalent commits
    commits=""
    while read commit; do

        commit=`git rev-parse --short ${commit:2}`
        # check if commit is not in ignore list
        if [[ "$ignore_SHAs" != *"$commit"* ]]; then
            # check if commit is not already picked
            if git log --exit-code --grep "$commit" &> /dev/null; then
                # add commit to cherry-pick list
                commits="${commits} $commit"
            fi
        fi

    done <<< "$(git cherry $branch template/$remote_branch | grep -F +)"

    # cleanup when no new commits found
    if [ "$commits" == "" ]; then
        echo
        echo "========================================================"
        echo "          You are up to date with the template          "
        echo "========================================================"
        echo
        cleanup
    fi

    # notify about a new update when "check only" mode is active and cleanup
    if [ "$check_only" == "true" ]; then
        echo
        echo "========================================================"
        echo "              The template has new changes              "
        echo 
        echo "         Run the 'Update Template' task to pull         "
        echo "          changes from the template repository          "
        echo "========================================================"
        echo
        cleanup
    fi

    commits="${commits:1}"

    # add commits to tplver file for commit message to prevent double picking
    >"$tplver_file" echo "$commits"

    # cherry-pick new commits from template
    git cherry-pick --keep-redundant-commits -x $commits &> /dev/null

    start_merge
}

function start()
{
    init_empty
    
    # if update branch not exists, start update else continue cherry-pick and merge
    check_branch start_update

    # skip empty picks and continue with cherry-pick 
    pick_sequencer="continue"
    git diff --cached --quiet --exit-code && pick_sequencer="skip"
    git -c core.editor=true cherry-pick --$pick_sequencer &> /dev/null
    start_merge
}

check_git
check_internet
if [ "$1" != "--check" ]; then pull_script "$script_path" "$1"; fi

check_git_version

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_usage
elif [ "$1" == "--abort" ]; then
    abort
elif [ "$1" == "--check" ]; then
    check_only="true"
    start
else
    start
fi

exit