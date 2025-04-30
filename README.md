# Rotafile

A powerful bash tool for automatic file rotation and cleanup based on file age, with flexible time period options.

## Features

- Rotate and delete files older than a specified time period
- Support for multiple time units:
  - Days (d)
  - Weeks (w)
  - Months (m)
  - Years (y)
- Optional file pattern matching
- Force mode for automation (cron jobs)
- Preview files before deletion
- Confirmation prompt in interactive mode
- No depedency needed, using built-in tool

## ⚠️ Caution

**WARNING**: Rotafile permanently deletes files. Please use with care:

- **Always run without `--force` first** to preview which files will be deleted
- **Back up important data** before running on critical directories
- **Double-check file patterns** as a typo could lead to deleting the wrong files
- **Be especially careful with root/sudo access** and system directories
- **Test in a safe environment** before setting up in cron jobs
- **Start with small time periods** and gradually increase as needed

**DISCLAIMER**: The author of this tool assumes no liability for data loss, damages, or any consequences resulting from the use of Rotafile. Files deleted due to user error, misconfigurations, or any other circumstances are solely the responsibility of the user. Always verify commands before execution.

Once files are deleted, they cannot be recovered unless you have backups or filesystem-level recovery tools. Rotafile does not move files to a trash/recycle bin.

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/aancw/rotafile.git
   cd rotafile
   ```

2. Make the script executable:
   ```bash
   chmod +x rotafile.sh
   ```

3. Optional: Install system-wide
   ```bash
   sudo ./install.sh
   ```

## Usage

Basic syntax:
```bash
./rotafile.sh [directory] [time_period] [file_pattern] [options]
```

### Parameters

- `directory`: The directory to search for files
- `time_period`: Age of files to delete with unit (e.g., 5d, 2w, 3m, 1y)
- `file_pattern`: (Optional) Pattern to match specific files (e.g., "*.log")

### Options

- `--force`: Skip confirmation prompt (useful for cron jobs)
- `--dry-run`: Show what would be deleted without actually deleting anything
- `--log=FILE`: Write output to a log file (in addition to stdout)
- `--help`: Display usage information

### Examples

Delete all files older than 5 days in /tmp:
```bash
./rotafile.sh /tmp 5d
```

Delete log files older than 2 weeks in /var/log:
```bash
./rotafile.sh /var/log 2w "*.log"
```

Do a dry run and save the results to a log file:
```bash
./rotafile.sh /backup 3m "backup-*.tar.gz" --dry-run --log=/var/log/rotafile.log
```

Delete backup files older than 3 months without confirmation:
```bash
./rotafile.sh /backup 3m "backup-*.tar.gz" --force
```

Delete all files older than 1 year in /archive:
```bash
./rotafile.sh /archive 1y
```

## Automated Usage (Cron)

To set up a scheduled task for automatic file rotation:

```bash
# Edit crontab
crontab -e

# Add a line like this to run daily at 2:00 AM
0 2 * * * /path/to/rotafile.sh /var/log 30d "*.log" --force > /path/to/rotation.log 2>&1
```

## Time Units

- `d` - Days (e.g., 5d = 5 days)
- `w` - Weeks (e.g., 2w = 2 weeks = 14 days)
- `m` - Months (e.g., 3m = 3 months ≈ 90 days)
- `y` - Years (e.g., 1y = 1 year ≈ 365 days)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.