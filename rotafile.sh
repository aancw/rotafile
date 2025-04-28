#!/bin/bash

# Rotafile - Time-based File Rotation and Deletion Script
# This script allows deleting files based on specified time periods

# Usage:
# ./rotafile.sh [directory] [time_period] [file_pattern] [--force]
#
# [directory]    - The directory to search for files to delete
# [time_period]  - Time period with unit (e.g., 5d, 2w, 3m, 1y)
#                  d=days, w=weeks, m=months, y=years
# [file_pattern] - Optional. Pattern to match files (e.g., "*.log" or "*")
# [--force]      - Optional. Skip confirmation prompt (useful for cron jobs)

# Function to display usage information
show_usage() {
    echo "Usage: $0 [directory] [time_period] [file_pattern] [options]"
    echo "Example 1: $0 /var/log 5d"
    echo "Example 2: $0 /var/log 5d \"*.log\" --force"
    echo ""
    echo "Parameters:"
    echo "  [directory]    - The directory to search for files to delete"
    echo "  [time_period]  - Time period with unit (e.g., 5d, 2w, 3m, 1y)"
    echo "                   d=days, w=weeks, m=months, y=years"
    echo "  [file_pattern] - Optional. Pattern to match files (e.g., \"*.log\")"
    echo "                   If omitted, all files (*) will be matched"
    echo ""
    echo "Options:"
    echo "  --force        - Skip confirmation prompt (useful for cron jobs)"
    echo "  --dry-run      - Show what would be deleted without actually deleting"
    echo "  --help         - Display this help message"
}

# Parse arguments
FORCE_MODE=0
DRY_RUN=0
DIRECTORY=""
TIME_PERIOD=""
FILE_PATTERN=""

# Process arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            FORCE_MODE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            # Assign positional arguments
            if [ -z "$DIRECTORY" ]; then
                DIRECTORY="$1"
            elif [ -z "$TIME_PERIOD" ]; then
                TIME_PERIOD="$1"
            else
                FILE_PATTERN="$1"
            fi
            shift
            ;;
    esac
done

# Set default file pattern if not provided
if [ -z "$FILE_PATTERN" ]; then
    FILE_PATTERN="*"
fi

# Check if required arguments are provided
if [ -z "$DIRECTORY" ] || [ -z "$TIME_PERIOD" ]; then
    echo "Error: Insufficient arguments"
    show_usage
    exit 1
fi

# Check if directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

# Extract time value and unit from the time period
if [[ "$TIME_PERIOD" =~ ^([0-9]+)([dwmyDWMY])$ ]]; then
    TIME_VALUE="${BASH_REMATCH[1]}"
    TIME_UNIT="${BASH_REMATCH[2]}"
else
    echo "Error: Invalid time period format. Use formats like 5d, 2w, 3m, 1y"
    exit 1
fi

# Convert time unit to days for find command
case "$TIME_UNIT" in
    d|D) 
        DAYS="$TIME_VALUE"
        TIME_UNIT_FULL="days"
        ;;
    w|W) 
        DAYS=$((TIME_VALUE * 7))
        TIME_UNIT_FULL="weeks"
        ;;
    m|M) 
        DAYS=$((TIME_VALUE * 30))
        TIME_UNIT_FULL="months"
        ;;
    y|Y) 
        DAYS=$((TIME_VALUE * 365))
        TIME_UNIT_FULL="years"
        ;;
    *)
        echo "Error: Invalid time unit. Use d=days, w=weeks, m=months, y=years"
        exit 1
        ;;
esac

# Display summary of operations
echo "========== Rotafile Summary =========="
echo "Directory: $DIRECTORY"
echo "Time Period: $TIME_VALUE $TIME_UNIT_FULL ($DAYS days)"
echo "File Pattern: $FILE_PATTERN"
echo "Force Mode: $([ $FORCE_MODE -eq 1 ] && echo "Enabled" || echo "Disabled")"
echo "Dry Run: $([ $DRY_RUN -eq 1 ] && echo "Enabled" || echo "Disabled")"
echo "===================================="

# Find and list files older than the specified time period
echo "The following files will be deleted:"
FILES_TO_DELETE=$(find "$DIRECTORY" -type f -name "$FILE_PATTERN" -mtime +$DAYS -print)
echo "$FILES_TO_DELETE"

# Count number of files to delete
FILE_COUNT=$(echo "$FILES_TO_DELETE" | grep -v "^$" | wc -l)
echo "Total files to delete: $FILE_COUNT"

# Ask for confirmation if not in force mode and not in dry run mode
if [ $FORCE_MODE -eq 0 ] && [ $DRY_RUN -eq 0 ]; then
    read -p "Do you want to proceed with deletion? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Execute deletion unless in dry run mode
if [ $DRY_RUN -eq 1 ]; then
    echo "DRY RUN: No files were deleted."
elif [ $FILE_COUNT -gt 0 ]; then
    find "$DIRECTORY" -type f -name "$FILE_PATTERN" -mtime +$DAYS -delete
    echo "Files rotated successfully."
else
    echo "No files to rotate."
fi