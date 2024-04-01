#!/bin/bash

file_path="$1"  # The first argument passed to the script will be the file path

if [ -z "$file_path" ]; then
    echo "Please provide the path to the multifasta file as an argument."
    echo "Usage: $0 /path/to/your/multifasta_file.fasta"
    exit 1
fi

if [ -f "$file_path" ]; then
    echo "File exists."
    if [[ $(file -b --mime-type "$file_path") == "text/plain" ]]; then
        echo "File is in text/plain format."

        # Read the file line by line
        while IFS= read -r line
        do
            # Check if the line starts with '>'
            if [[ $line == ">"* ]]; then
                if [[ -n "$sequence_data" ]]; then
                    # Validate the previous sequence data
                    sequence_data=$(tr -d '\n[:space:]' <<< "$sequence_data")
                    if [[ $sequence_data =~ [^ACGTUacgtu] ]]; then
                        echo "Invalid characters found in sequence: $header"
                    else
                        echo "Sequence $header contains valid characters."
                    fi
                fi

                # Extract the header and remove leading '>'
                header=${line#>}
                # Clear the sequence data buffer for the new sequence
                sequence_data=""
            else
                # Append the sequence data to the buffer
                sequence_data+="$line"
            fi
        done < "$file_path"

        # Validate the last sequence in the file
        sequence_data=$(tr -d '\n[:space:]' <<< "$sequence_data")
        if [[ $sequence_data =~ [^ACGTUacgtu] ]]; then
            echo "Invalid characters found in sequence: $header"
        else
            echo "Sequence $header contains valid characters."
        fi

    else
        echo "File is not in text/plain format."
    fi
else
    echo "File does not exist or is not accessible."
fi
