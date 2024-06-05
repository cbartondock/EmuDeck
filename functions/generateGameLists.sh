#!/bin/bash
generateGameLists() {
    pegasus_setPaths
    python $HOME/.config/EmuDeck/backend/tools/generate_game_lists.py "$romsPath"
}

generateGameListsJson() {
    cat $HOME/emudeck/roms_games.json
    generateGameLists_artwork $1 &> /dev/null &
}
log=$HOME/.config/EmuDeck/backend.log
generateGameLists_artwork() {
    json=$(cat "$HOME/emudeck/roms_games.json")
    platforms=$(echo "$json" | jq -r '.[].id')
    echo "generateGameLists_artwork" > $log
    accountfolder="$HOME/.steam/steam/userdata/$1";
    echo $accountfolder >> $log;
    dest_folder="$accountfolder/config/grid/"
    mkdir -p "$dest_folder"

    declare -A processed_games

    for platform in $platforms; do
        echo "Processing platform: $platform" >> $log
        games=$(echo "$json" | jq -r --arg platform "$platform" '.[] | select(.id == $platform) | .games[]?.name')

        declare -a download_array
        declare -a download_dest_paths

        for game in $games; do
            file_to_check="$dest_folder${game// /_}*"

           if ! ls $file_to_check 1> /dev/null 2>&1 && [ -z "${processed_games[$game]}" ]; then
                echo -ne "$game" >> $log

                response=$(curl -s -G "https://bot.emudeck.com/steamdbimg.php?name=$game&platform=$platform")
                game_name=$(echo "$response" | jq -r '.name')
                game_img_url=$(echo "$response" | jq -r '.img')
                filename=$(basename "$game_img_url")
                dest_path="$dest_folder$game.jpg"


                if [ ! -f "$dest_path" ] && [ $game_img_url != "null" ]; then
                    echo -e " - $game_img_url" - $dest_path >> $log
                    download_array+=("$game_img_url")
                    download_dest_paths+=("$dest_path")
                    processed_games[$game]=1
                else
                    echo -e " - No picture"
                fi
            fi

            # Download in batches of 10
            if [ ${#download_array[@]} -ge 10 ]; then
                echo "" >> $log
                echo "Start batch" >> $log
                for i in "${!download_array[@]}"; do
                    {
                        curl -s -o "${download_dest_paths[$i]}" "${download_array[$i]}" > /dev/null 2>&1
                    } &
                done
                wait
                # Clear the arrays for the next batch
                download_array=()
                download_dest_paths=()
                echo "Completed batch" >> $log
                echo "" >> $log
            fi

        done

        # Download images for the current platform
        if [ ${#download_array[@]} -ne 0 ]; then
            for i in "${!download_array[@]}"; do
                {
                    curl -s -o "${download_dest_paths[$i]}" "${download_array[$i]}"
                } &
            done
        fi
        wait

        echo "Completed downloads for platform: $platform" >> $log
    done
}
