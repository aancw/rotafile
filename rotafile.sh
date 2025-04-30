#!/bin/bash

# Rotafile - Time-based File Rotation and Deletion Script
# This script allows deleting files based on specified time periods

# Usage:
# ./rotafile.sh [directory] [time_period] [file_pattern] [options]
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
    echo "  --log=FILE     - Write output to a log file in addition to screen"
    echo "  --help         - Display this help message"
}

# Parse arguments
FORCE_MODE=0
DRY_RUN=0
DIRECTORY=""
TIME_PERIOD=""
FILE_PATTERN=""
LOG_FILE=""

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
        --log=*)
            LOG_FILE="${1#*=}"
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

# Set up logging function
log_message() {
    local message="$1"
    echo "$message"
    
    if [ -n "$LOG_FILE" ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# Initialize log file if specified
if [ -n "$LOG_FILE" ]; then
    # Create log directory if it doesn't exist
    LOG_DIR=$(dirname "$LOG_FILE")
    if [ ! -d "$LOG_DIR" ] && [ "$LOG_DIR" != "." ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: Could not create log directory: $LOG_DIR"
            exit 1
        fi
    fi
    
    # Create or truncate the log file
    echo "Rotafile Log - $(date)" > "$LOG_FILE"
    echo "Command: $0 $DIRECTORY $TIME_PERIOD $FILE_PATTERN" >> "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
fi

# Display summary of operations
log_message "========== Rotafile Summary =========="
log_message "Directory: $DIRECTORY"
log_message "Time Period: $TIME_VALUE $TIME_UNIT_FULL ($DAYS days)"
log_message "File Pattern: $FILE_PATTERN"
log_message "Force Mode: $([ $FORCE_MODE -eq 1 ] && echo "Enabled" || echo "Disabled")"
log_message "Dry Run: $([ $DRY_RUN -eq 1 ] && echo "Enabled" || echo "Disabled")"
if [ -n "$LOG_FILE" ]; then
    log_message "Logging to: $LOG_FILE"
fi
log_message "===================================="

# Find and list files older than the specified time period
log_message "The following files will be deleted:"
log_message "------------------------------------"
log_message "TIMESTAMP            SIZE    FILE   "
log_message "------------------------------------"

# Create a temporary file to store file info with sortable dates
TEMP_FILE="/tmp/rotafile_list.$$"
touch "$TEMP_FILE"

# Function to convert file size to human-readable format
human_readable_size() {
    local size=$1
    local suffix=("B" "K" "M" "G" "T")
    local scale=0
    
    while (( size > 1024 )); do
        # Integer division with bash
        size=$((size / 1024))
        scale=$((scale + 1))
    done
    
    echo "${size}${suffix[$scale]}"
}

# Find all matching files and get their information
find "$DIRECTORY" -type f -name "$FILE_PATTERN" -mtime +$DAYS -print | while read FILE; do
    if [ -f "$FILE" ]; then
        # Get epoch time for sorting
        EPOCH=$(stat -c %Y "$FILE")
        
        # Get file size
        SIZE=$(stat -c %s "$FILE")
        SIZE_HR=$(human_readable_size "$SIZE")
        
        # Get human-readable date in format we want to display
        DATE_DISPLAY=$(date -r "$FILE" "+%b %d %Y")
        
        # Store with epoch first for sorting
        echo "$EPOCH $DATE_DISPLAY $SIZE_HR $FILE" >> "$TEMP_FILE"
    fi
done

# Sort by timestamp (epoch) and display
if [ -s "$TEMP_FILE" ]; then
    sort -n "$TEMP_FILE" | while read -r LINE; do
        # Extract the sorted information (skip epoch, which was just for sorting)
        TIMESTAMP=$(echo "$LINE" | awk '{print $2, $3, $4}')
        SIZE=$(echo "$LINE" | awk '{print $5}')
        FILE=$(echo "$LINE" | cut -d' ' -f6-)
        
        # Print in formatted table
        output=$(printf "%-20s %-7s %s\n" "$TIMESTAMP" "$SIZE" "$FILE")
        log_message "$output"
    done
    
    # Count the files
    FILE_COUNT=$(wc -l < "$TEMP_FILE")
else
    FILE_COUNT=0
    log_message "No matching files found."
fi

# Clean up temporary file
rm -f "$TEMP_FILE"

log_message "------------------------------------"
log_message "Total files to delete: $FILE_COUNT"

# Ask for confirmation if not in force mode and not in dry run mode
if [ $FORCE_MODE -eq 0 ] && [ $DRY_RUN -eq 0 ] && [ $FILE_COUNT -gt 0 ]; then
    read -p "Do you want to proceed with deletion? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_message "Operation cancelled."
        
        # Add final timestamp to log if logging enabled
        if [ -n "$LOG_FILE" ]; then
            echo "----------------------------------------" >> "$LOG_FILE"
            echo "Cancelled at: $(date)" >> "$LOG_FILE"
        fi
        
        exit 0
    fi
fi

# Execute deletion unless in dry run mode
if [ $DRY_RUN -eq 1 ]; then
    log_message "DRY RUN: No files were deleted."
elif [ $FILE_COUNT -gt 0 ]; then
    find "$DIRECTORY" -type f -name "$FILE_PATTERN" -mtime +$DAYS -delete
    log_message "Files rotated successfully."
else
    log_message "No files to rotate."
fi

# Add final timestamp to log if logging enabled
if [ -n "$LOG_FILE" ]; then
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "Completed at: $(date)" >> "$LOG_FILE"
    echo "Result: $([ $DRY_RUN -eq 1 ] && echo "Dry run, no files deleted" || ([ $FILE_COUNT -gt 0 ] && echo "$FILE_COUNT files rotated" || echo "No files rotated"))" >> "$LOG_FILE"
fi