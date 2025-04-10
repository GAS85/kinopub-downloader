#!/bin/bash

# URL to the XML file
XML_URL="https://kino.pub/podcast/get/82..."

# Path files to be downloaded, e.g. /home/user/podcasts/
DOWNLOAD_PATH="/home/user/podcasts/"  # Make sure to set the appropriate path

# Set Temp File location
TMP_XML=/tmp/podcast.xml

# Set User Agent
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"

cd "$DOWNLOAD_PATH" || { echo "Error - Can't find directory $DOWNLOAD_PATH, please make sure that it is correct"; exit 0; }

# Download the XML file
curl -A "$USER_AGENT" -s "$XML_URL" -o "$TMP_XML"

# Use xmllint to parse the XML and extract the URLs and titles
# Loop over each item, extract the enclosure url and title
xmlstarlet sel -t -m "//item" -v "concat(title, '|', enclosure/@url)" -n $TMP_XML | while IFS= read -r line
do
    # Split the title and URL
    title=$(echo "$line" | awk -F'|' '{print $1}')
    url=$(echo "$line" | awk -F '|' '{print $2}')

    # Sanitize the title to use it as a filename (replace spaces with underscores and remove special chars)
    safe_title=$(echo "$title" | tr -s ' ' '_' | tr -cd '[:alnum:]_-')

    # Download the video using wget and save it with the sanitized title
    echo "Downloading: $title"
    curl -L -o "${safe_title}.mp4" -A "$USER_AGENT" "$url"
done

rm "$TMP_XML"
echo "Finished"

exit 0
