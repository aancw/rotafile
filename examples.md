# Usage Examples for Rotafile

This document provides detailed examples of how to use Rotafile for various scenarios.

## Basic Usage Examples

### Delete files older than 7 days

```bash
# Delete all files older than 7 days in the current directory
./rotafile.sh . 7d
```

### See what would be deleted without actually deleting

```bash
# Preview files that would be deleted without actually deleting them
./rotafile.sh /var/log 2w "*.log" --dry-run
```

### Delete log files older than 2 weeks

```bash
# Delete only .log files older than 2 weeks in /var/log
./rotafile.sh /var/log 2w "*.log"
```

### Delete backup files older than 3 months

```bash
# Delete backup archives older than 3 months without confirmation
./rotafile.sh /backup 3m "backup*.tar.gz" --force
```

### Delete old documents

```bash
# Delete PDFs and DOCs older than 1 year
./periodic_delete.sh ~/Documents 1y "*.pdf" 
./periodic_delete.sh ~/Documents 1y "*.doc*"
```

## Advanced Usage

### Multiple patterns with OR logic

```bash
# Delete both log and tmp files older than 5 days
find /var/log -type f \( -name "*.log" -o -name "*.tmp" \) -mtime +5 -delete
```

Note: For multiple patterns, you might need to use `find` directly as shown above, or run rotafile.sh multiple times.

### Using with sudo

```bash
# Delete system logs older than 30 days (requires permissions)
sudo ./rotafile.sh /var/log 30d "*.log"
```

### Delete empty directories after file deletion

```bash
# Delete files older than 30 days, then remove empty directories
./rotafile.sh /path/to/dir 30d --force
find /path/to/dir -type d -empty -delete
```

## Cron Job Examples

### Daily cleanup at midnight

```bash
# Add to crontab with: crontab -e
0 0 * * * /usr/local/bin/rotafile /tmp 7d --force > /dev/null 2>&1
```

### Weekly log rotation with safety

```bash
# First run a dry run and log the output (Monday at 1 AM)
0 1 * * 1 /usr/local/bin/rotafile /var/log 2w "*.log" --dry-run > /home/user/logs/rotation-preview.log 2>&1

# Then run the actual rotation if everything looks good (Wednesday at 1 AM)
0 1 * * 3 /usr/local/bin/rotafile /var/log 2w "*.log" --force > /home/user/logs/rotation.log 2>&1
```

### Monthly backup cleanup

```bash
# Run on the 1st of each month at 3:00 AM
0 3 1 * * /usr/local/bin/rotafile /backup 3m --force > /home/user/logs/backup-rotation.log 2>&1
```

## Safety Tips

1. Always run without `--force` first to preview which files will be deleted
2. Consider backing up important directories before mass deletion
3. Test with smaller time periods first before setting up automation
4. Redirect output to a log file when using in cron jobs