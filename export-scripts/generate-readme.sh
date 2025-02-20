#!/bin/bash

# Define directories
BASE_DIR="../sketches"
README_DIR="../README"
README_FILE="/tmp/readme_output.md"

# Create the README directory if it doesn't exist
mkdir -p "$README_DIR"

# Start Markdown table
echo "|  |  |  |" > "$README_FILE"
echo "|---|---|---|" >> "$README_FILE"

# Collect thumbnails into rows of three
row_count=0
row=""

# Iterate over project directories in BASE_DIR
for PROJECT_DIR in "$BASE_DIR"/*/; do
    # Get the base name of the project
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    
    # Detect output file with possible extensions
    OUTPUT_FILE=""
    for ext in jpg jpeg gif; do
        if [[ -f "${PROJECT_DIR}output.$ext" ]]; then
            OUTPUT_FILE="${PROJECT_DIR}output.$ext"
            break
        fi
    done

    if [[ -z "$OUTPUT_FILE" ]]; then
        echo "No output file found for $PROJECT_NAME" >&2
        continue
    fi

    THUMBNAIL_FILE="README/${PROJECT_NAME}.jpg"
    FILE_EXT="${OUTPUT_FILE##*.}"

    echo "Processing $OUTPUT_FILE -> $THUMBNAIL_FILE"
    
    # Convert and resize image
    if [[ "$FILE_EXT" == "gif" ]]; then
        ffmpeg -y -i "$OUTPUT_FILE" -vf "scale=200:200:force_original_aspect_ratio=decrease" -frames:v 1 "$THUMBNAIL_FILE"
    else
        convert "$OUTPUT_FILE" -resize 200x200^ -gravity center -extent 200x200 "$THUMBNAIL_FILE"
    fi

    # Append linked thumbnail to row
    row+="[![]($THUMBNAIL_FILE)](${PROJECT_DIR#../}) | "
    ((row_count++))

    # If we have three thumbnails in a row, write to the file
    if [[ $row_count -eq 3 ]]; then
        echo "| $row" >> "$README_FILE"
        row=""
        row_count=0
    fi
done

# If there are remaining thumbnails, pad and write the last row
if [[ $row_count -gt 0 ]]; then
    while [[ $row_count -lt 3 ]]; do
        row+=" | "
        ((row_count++))
    done
    echo "| $row" >> "$README_FILE"
fi

# Copy markdown output to clipboard (MacOS)
cat "$README_FILE" | pbcopy

echo "Markdown grid copied to clipboard."