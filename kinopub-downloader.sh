#!/bin/bash

# URL to the XML file
XML_URL="https://kino.pub/podcast/get/82..."

# Path files to be downloaded, e.g. /home/user/podcasts/
DOWNLOAD_PATH="/home/user/podcasts/"  # Make sure to set the appropriate path

# You can set Serie number to start from, e.g. s1e3 will download s1e3 and everything after.
START_FROM=""

# You can set number of files to be download, e.g. 3
STOP_AFTER=""

# You can set proxy here, please refer to CURL supported proxy
PROXY=""

# Set Temp File location
TMP_XML=/tmp/podcast.xml

# Set User Agent
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"

cd "$DOWNLOAD_PATH" || { echo "Error - Can't find directory $DOWNLOAD_PATH, please make sure that it is correct"; exit 0; }

if [ -n "$PROXY" ]; then
    CURL_USE_PROXY="-x $PROXY"
else
    CURL_USE_PROXY=""
fi

# Download the XML file
curl "$CURL_USE_PROXY" -L -A "$USER_AGENT" -s "$XML_URL" -o "$TMP_XML"

COUNTER=0

# Use xmllint to parse the XML and extract the URLs and titles
# Loop over each item, extract the enclosure url and title
xmlstarlet sel -t -m "//item" -v "concat(title, '|', enclosure/@url)" -n $TMP_XML | sort | awk "/$START_FROM/ {found=1} found" | while IFS= read -r line
do
    # Split the title and URL
    title=$(echo "$line" | awk -F'|' '{print $1}')
    url=$(echo "$line" | awk -F '|' '{print $2}')

    # Sanitize the title to use it as a filename (replace spaces with underscores and remove special chars)
    safe_title=$(echo "$title" | tr -s ' ' '_' | tr -cd '[:alnum:]_-')

    # Check if file already exists, if so skip download
    if [ -f "${safe_title}.mp4" ]; then
        echo "File already exists: ${safe_title}.mp4, skipping download."
    else
        # Download the video using wget and save it with the sanitized title
        echo "Downloading: $title"
        curl "$CURL_USE_PROXY" -L -o "${safe_title}.mp4" -A "$USER_AGENT" "$url"

        if [ -n "$STOP_AFTER" ]; then
            ((COUNTER++));
            if [ "$STOP_AFTER" == "$COUNTER"  ] ; then
                break
            fi
        fi
    fi
done

rm "$TMP_XML"
echo "Finished"

exit 0
