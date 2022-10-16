#
# Copyright (c) 2022 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

#!/bin/bash

author_avatar_dir="./out/images/"
cached_data_file="./out/history.cache"

# maximum commits to show in the history
commit_limit="5"

# commits ignored in the generated history (seperate with space)
ignore_SHAs=""

jq_bin_download="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32"
jq_bin_path="./out/bin/jq-linux32"

# List of Gitmojis that will be removed in the commit message (seperate with space)
#   curl -s https://raw.githubusercontent.com/carloscuesta/gitmoji/master/src/data/gitmojis.json | jq -r .gitmojis[].code
gitmojis=":art: :zap: :fire: :bug: :ambulance: :sparkles: :memo: :rocket: :lipstick: :tada: :white_check_mark: :lock: :closed_lock_with_key: :bookmark: :rotating_light: :construction: :green_heart: :arrow_down: :arrow_up: :pushpin: :construction_worker: :chart_with_upwards_trend: :recycle: :heavy_plus_sign: :heavy_minus_sign: :wrench: :hammer: :globe_with_meridians: :pencil2: :poop: :rewind: :twisted_rightwards_arrows: :package: :alien: :truck: :page_facing_up: :boom: :bento: :wheelchair: :bulb: :beers: :speech_balloon: :card_file_box: :loud_sound: :mute: :busts_in_silhouette: :children_crossing: :building_construction: :iphone: :clown_face: :egg: :see_no_evil: :camera_flash: :alembic: :mag: :label: :seedling: :triangular_flag_on_post: :goal_net: :dizzy: :wastebasket: :passport_control: :adhesive_bandage: :monocle_face: :coffin: :test_tube: :necktie: :stethoscope: :bricks: :technologist:"

title=""
prefix=""
prefix_entry=""

function show_usage()
{
    echo "usage: history.sh <timeline | table> [title] [commit limit] [ignore SHAs]"
    echo
    echo
    echo "This script prints LaTeX code to"
    echo "display the current git history"
    echo "in your document."
    echo "The 'history.sty'-file is required."
    exit
}

function jq_binary() {
    arch=$(uname -i)

    if [[ $arch == x86_64* ]] || [[ $arch == i*86 ]]; then
        
        # download the jq-tool to parse json
        if [ ! -e $jq_bin_path ]; then
            if [ ! -e "$(dirname $jq_bin_path)" ]; then mkdir -p "$(dirname $jq_bin_path)"; fi
            curl -Ls "$jq_bin_download" -o $jq_bin_path
            chmod +x $jq_bin_path
        fi

        return 0
    fi

    return 1
}

function start()
{
    if [ "$1" ]; then title="[$1]"; fi
    if [ "$2" ]; then commit_limit="$2"; fi
    if [ "$3" ]; then ignore_SHAs="$3"; fi

    # set no commit limit if parameter equal '0'
    if [ "$commit_limit" == "0" ]; then commit_limit=""; fi

    # prepend argument got git command when commit limit is set
    if [ "$commit_limit" != "" ]; then commit_limit="-n ${commit_limit}"; fi

    echo "\begin{$prefix}$title"

    # get github api url of current repo
    github_api="$(git config --get remote.origin.url | grep -F https://github.com/)"
    github_api="${github_api/'.git'/''}"
    github_api="${github_api/'//github.com/'/'//api.github.com/repos/'}"

    # loop through commits and get date and sha
    commit_counter=0
    while read commit_data; do
        # reset commit variables
        read -r commit_date commit_sha commit_msg commit_author <<< ""
        read -r github_sha_url github_author_url github_author_avatar_url github_author_avatar_file <<< ""

        # separate date and sha to write variables
        commit_date="$(echo $commit_data | cut -d ',' -f 1)"
        commit_sha="$(echo $commit_data | cut -d ',' -f 2)"

        # check if commit is not in ignore list
        if [[ "$ignore_SHAs" != *"$commit_sha"* ]]; then
            # get current commit message and author (skip already handled commits)
            commit_msg="$(git log -n 1 --skip $commit_counter --pretty=format:%s)"
            commit_author="$(git log -n 1 --skip $commit_counter --pretty=format:%aN)"

            if ! git log -n 1 --skip $commit_counter --pretty=format:%b | grep "ignore-in-history" > /dev/null; then
                # remove gitmoji-codes from commit message
                for i in $gitmojis; do commit_msg=${commit_msg/"$i "/""}; done

                use_cached_data=false

                # read cache file line by line
                if [ -e "$cached_data_file" ]; then cache_commit_data=$(cat "$cached_data_file" | grep -F $commit_sha); fi
                if [ $cache_commit_data ]; then
                    commit_author="$(echo $cache_commit_data | cut -d ',' -f 3)"
                    github_sha_url="$(echo $cache_commit_data | cut -d ',' -f 2)"
                    github_author_url="$(echo $cache_commit_data | cut -d ',' -f 4)"
                    use_cached_data=true
                fi

                # retrieve additional data from github if repo is hosted on github, the jq parse tool is available and github.com is reachable
                if [ "$github_api" != "" ] && [ "$use_cached_data" != "true" ]; then
                    if jq --version &> /dev/null || jq_binary; then
                        if [ "${CI}" ] || timeout 1 ping github.com -c 1 &> /dev/null; then
                            # fetch & parse data from GitHub and separate to write variables
                            github_data=`curl -s $github_api/commits/$commit_sha | $(jq_binary && echo $jq_bin_path || echo jq) -r .html_url,.author.login,.author.html_url,.author.avatar_url`

                            github_sha_url="$(echo $github_data | grep -v 'null' | cut -d ' ' -f 1)"
                            github_author="$(echo $github_data | grep -v 'null' | cut -d ' ' -f 2)"
                            github_author_url="$(echo $github_data | grep -v 'null' | cut -d ' ' -f 3)"
                            github_author_avatar_url="$(echo $github_data | grep -v 'null' | cut -d ' ' -f 4)"
                        
                            # check if data was successfully parsed
                            if [ "$github_author" != "" ]; then commit_author="$github_author"; fi
                            if [ "$github_author_avatar_url" != "" ]; then
                                # download author avatar
                                if [ ! -e "$author_avatar_dir" ]; then mkdir -p "$author_avatar_dir"; fi
                                if [ ! -e "$author_avatar_dir$commit_author.png" ] && [ "$github_author_avatar_url" != "" ]; then
                                    parm_size="size=50"
                                    if [ "${github_author_avatar_url/'?'/''}" == "$github_author_avatar_url" ]; then
                                        parm_size="?$parm_size"
                                    else
                                        parm_size="&$parm_size"
                                    fi

                                    curl -s "$github_author_avatar_url$parm_size" -o "$author_avatar_dir$commit_author.png"
                                fi

                                # cache parsed data
                                if [ ! -e "$(dirname $cached_data_file)" ]; then mkdir -p "$(dirname $cached_data_file)"; fi
                                echo "$commit_sha,$github_sha_url,$commit_author,$github_author_url" >> "$cached_data_file"
                            fi
                        fi
                    fi
                fi

                # prepare data for LaTeX document
                if [ -e "$author_avatar_dir$commit_author.png" ]; then github_author_avatar_file="[$commit_author.png]"; fi

                if [ "$commit_date" != "" ]; then commit_date="{$commit_date}"; fi
                if [ "$commit_sha" != "" ]; then commit_sha="{$commit_sha}"; fi
                if [ "$commit_msg" != "" ]; then commit_msg="{\directlua{tex.sprint(-2, \"\luaescapestring{$commit_msg}\")}}"; fi
                if [ "$commit_author" != "" ]; then commit_author="{$commit_author}"; fi

                if [ "$github_sha_url" != "" ]; then github_sha_url="[$github_sha_url]"; fi
                if [ "$github_author_url" != "" ]; then github_author_url="[$github_author_url]"; fi

                # output combined data
                echo "\\$prefix_entry$commit_date$commit_sha$github_sha_url$commit_author$github_author_url$github_author_avatar_file$commit_msg"
            fi
        fi

        (( commit_counter += 1 ))

    done <<< "$(git log $commit_limit --pretty=format:%as,%h)"

    echo "\end{$prefix}"
}

if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_usage
elif [ "$1" == "timeline" ]; then
    prefix="HistoryTimeline"
    prefix_entry="HistoryTlEntry"
    start "$2" "$3" "$4"
elif [ "$1" == "table" ]; then
    prefix="HistoryTable"
    prefix_entry="HistoryTabEntry"
    start "$2" "$3" "$4"
fi

exit