#!/bin/bash

# URL to the XML file
XML_URL="https://kino.pub/podcast/get/82..."

# Path files to be downloaded, e.g. /home/user/podcasts/
DOWNLOAD_PATH="/home/user/podcasts/"  # Make sure to set the appropriate path

# You can set Serie number to start from, e.g. s1e3 will download s1e3 and everything after.
START_FROM=""

# You can set number of files to be download, e.g. 3, or keep it empty for no limit
STOP_AFTER="10"

# You can set proxy here, please refer to CURL supported proxy
PROXY=""

# Set Temp File location
TMP_XML=/tmp/podcast.xml

# Set User Agent
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"

# Move to the DOWNLOAD PATH
cd "$DOWNLOAD_PATH" || { echo "Error - Can't find directory $DOWNLOAD_PATH, please make sure that it is correct"; exit 0; }

# Apply Proxy settings
if [ -n "$PROXY" ]; then
    CURL_OPTIONS="-x $PROXY -L"
else
    CURL_OPTIONS="-L"
fi

# Parse and use Input
# Add START_FROM as Option
if [ -n "$1" ]; then
    START_FROM="$1"
fi

# Download the XML file
curl $CURL_OPTIONS -s -A "$USER_AGENT" "$XML_URL" -o "$TMP_XML"

COUNTER=0

# Use xmllint to parse the XML and extract the URLs and titles
# Loop over each item, extract the enclosure url and title
xmlstarlet sel -t -m "//item" -v "concat(title, '|', enclosure/@url)" -n $TMP_XML | sort | awk "/$START_FROM/ {found=1} found" | while IFS= read -r line
do
    # Split the title and URL
    title=$(echo "$line" | awk -F'|' '{print $1}')
    url=$(echo "$line" | awk -F '|' '{print $2}')

    # Sanitize the title to use it as a filename (replace spaces with underscores and remove special chars)
    safe_title=$(echo "$title" | tr -cd '[:alnum:]_ -')
    
    # Get the Content-Length header from the server
    content_length=$(curl -s $CURL_OPTIONS -A "$USER_AGENT" -I "$url" | grep -i "Content-Length:" | awk '{print $2}' | tr -d '\r')

    # Check if file already exists
    if [ -f "${safe_title}.mp4" ]; then

        # Get the size of the file already on disk
        file_size=$(stat -c %s "${safe_title}.mp4")

        # Compare Content-Length and file size
        if [ "$content_length" -eq "$file_size" ]; then
            echo "File already exists: ${safe_title}.mp4 (Content-Length matches), skipping download."
            continue
        else
            echo "File exists but size mismatch: ${safe_title}.mp4, re-downloading."
        fi
    fi

    # Download the video using wget and save it with the sanitized title
    echo "Downloading: $title, expected file size: $content_length"
    curl $CURL_OPTIONS -A "$USER_AGENT" -o "${safe_title}.mp4" "$url"

    if [ -n "$STOP_AFTER" ]; then
        ((COUNTER++));
        if [ "$STOP_AFTER" == "$COUNTER"  ] ; then
            break
        fi
    fi
done

rm "$TMP_XML"
echo "Finished"

exit 0
