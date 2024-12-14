#!/bin/bash

# Remove set -e temporarily for debugging
# set -e

# Initialize counters for total files, success, and failure
total_files=0
success_count=0
failure_count=0

# Find all Lua files recursively and process them
find . -type f -name "*.lua" | while read -r file; do
    echo "Found file: $file"  # Debugging line to see if files are being found
    ((total_files++))  # Increment total files count
    
    # Formatting with StyLua
    echo "✨ Formatting: $file"
    if stylua "$file" > /dev/null 2>&1; then
        echo "✅ StyLua formatting succeeded for $file"
        ((success_count++))  # Increment success count
    else
        echo "❌ StyLua formatting failed for $file"
        ((failure_count++))  # Increment failure count
    fi
done

# Display summary
echo "🔍 Total files reviewed: $total_files"
echo "✨ Files formatted successfully: $success_count"
echo "❌ Files failed to format: $failure_count"

if ((failure_count == 0)); then
    echo "✅ All files formatted successfully!"
else
    echo "⚠️ Some files failed to format. Please check the errors."
fi