#!/bin/bash
#
# Photo Organizer - A tool to organize photos based on EXIF metadata
# 

set -e

# Constants
readonly SCRIPT_NAME="Photo Organizer"
readonly SCRIPT_VERSION="1.0.0"

# Terminal colors and cursor movement - use escape chars directly
ESC=$(printf '\033')
readonly TERM_CLEAR_LINE="${ESC}[1G${ESC}[K"
readonly TERM_GREEN="${ESC}[32m"
readonly TERM_BLUE="${ESC}[34m"
readonly TERM_YELLOW="${ESC}[33m"
readonly TERM_RESET="${ESC}[0m"

# Function to draw a progress bar using simple ASCII characters
draw_progress_bar() {
  local percent=$1
  local processed=$2
  local total=$3
  local width=${4:-40}  # Reduced width to make room for file counts
  local completed=$(( width * percent / 100 ))
  local remaining=$(( width - completed ))
  
  # Calculate percent display with padding
  local percent_display
  percent_display="$(printf "%3d" "$percent")%"
  
  # Draw progress bar with simple ASCII
  printf "%s" "${TERM_CLEAR_LINE}${TERM_BLUE}[${TERM_GREEN}"
  printf "%${completed}s" | tr ' ' '#'
  printf "%s" "${TERM_BLUE}"
  printf "%${remaining}s" | tr ' ' '-'
  printf "%s" "] ${TERM_YELLOW}"
  printf " %s ${TERM_RESET}(%d/%d files)" "$percent_display" "$processed" "$total"
}

# Detect number of CPU cores for parallel processing
detect_cpu_cores() {
  local cores
  # Try different methods to get the number of CPU cores
  if command -v nproc &> /dev/null; then
    # Linux with coreutils
    cores=$(nproc)
  elif command -v sysctl &> /dev/null && sysctl -n hw.ncpu &> /dev/null; then
    # macOS and BSD
    cores=$(sysctl -n hw.ncpu)
  elif [[ -f /proc/cpuinfo ]]; then
    # Linux without nproc
    cores=$(grep -c processor /proc/cpuinfo)
  else
    # Default if we can't detect
    cores=4
  fi
  
  # Ensure we have at least 2 cores as default
  if [[ "$cores" -lt 2 ]]; then
    cores=2
  fi
  
  echo "$cores"
}

# Configuration with defaults
OUTPUT_DIR="organized_photos"
ORGANIZE_BY="date"  # Options: date, camera, both
DRY_RUN=false
COPY_MODE=true  # true = copy, false = move
VERBOSE=false
RECURSIVE=false
PARALLEL=true  # Enable parallel processing by default
MAX_JOBS=$(detect_cpu_cores)  # Default to number of CPU cores

# Function to display usage information
show_usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] SOURCE_DIRECTORY

Options:
  -o, --output DIR       Output directory (default: $OUTPUT_DIR)
  -b, --organize-by TYPE Organize by: date, camera, both (default: $ORGANIZE_BY)
  -m, --move             Move files instead of copying
  -d, --dry-run          Show what would be done without making changes
  -r, --recursive        Process directories recursively
  -v, --verbose          Enable verbose output
  -p, --parallel         Enable parallel processing (default)
  -s, --sequential       Disable parallel processing and use sequential processing
  -j, --jobs NUM         Number of parallel jobs (default: auto-detected: $MAX_JOBS)
  -h, --help             Display this help message and exit
  --version              Display version information and exit

Examples:
  $(basename "$0") ~/Pictures                       # Uses parallel processing by default
  $(basename "$0") -o ~/Sorted -b camera ~/Pictures
  $(basename "$0") -m -r ~/Pictures
  $(basename "$0") -s ~/Pictures                    # Use sequential processing
  $(basename "$0") -j 8 ~/Pictures                  # Use parallel processing with 8 jobs

EOF
}

# Function to display version information
show_version() {
  echo "$SCRIPT_NAME v$SCRIPT_VERSION"
}

# Function to check dependencies
check_dependencies() {
  if ! command -v exiftool &> /dev/null; then
    echo "Error: ExifTool is required but not installed."
    echo "Please install ExifTool and try again."
    echo "Installation instructions: https://exiftool.org/install.html"
    exit 1
  fi
}

# Function to log messages
log() {
  local level="$1"
  local message="$2"
  
  case "$level" in
    "INFO")
      prefix="[INFO] "
      ;;
    "ERROR")
      prefix="[ERROR] "
      # Send errors to stderr
      echo "${prefix}${message}" >&2
      return
      ;;
    "WARNING")
      prefix="[WARNING] "
      ;;
    "DEBUG")
      if [[ "$VERBOSE" = true ]]; then
        prefix="[DEBUG] "
        # Send debug messages to stderr
        echo "${prefix}${message}" >&2
        return
      else
        return 0
      fi
      ;;
    *)
      prefix=""
      ;;
  esac
  
  # Default output to stdout for INFO and WARNING
  echo "${prefix}${message}"
}

# Function to safely create directory
create_directory() {
  local dir="$1"
  
  if [[ "$DRY_RUN" = true ]]; then
    log "INFO" "Would create directory: $dir"
    return 0
  fi
  
  if [[ ! -d "$dir" ]]; then
    if ! mkdir -p "$dir"; then
      log "ERROR" "Failed to create directory: $dir"
      return 1
    fi
    log "DEBUG" "Created directory: $dir"
  else
    log "DEBUG" "Directory already exists: $dir"
  fi
  
  return 0
}

# Function to update missing EXIF date metadata 
update_exif_date() {
  local file="$1"
  local dest_file="$2"
  
  # Check if DateTimeOriginal exists
  local has_date_time_original
  has_date_time_original=$(exiftool -s3 -DateTimeOriginal "$file" 2>/dev/null)
  
  # If DateTimeOriginal is missing, try to add it
  if [[ -z "$has_date_time_original" ]]; then
    log "DEBUG" "DateTimeOriginal missing in $file, attempting to add it"
    
    local determined_date=""
    local date_source=""
    
    # Try other EXIF date fields in priority order
    for date_tag in "CreateDate" "DateCreated" "MediaCreateDate" "DateTime"; do
      determined_date=$(exiftool -s3 -"$date_tag" "$file" 2>/dev/null)
      if [[ -n "$determined_date" ]]; then
        date_source="$date_tag"
        break
      fi
    done
    
    # Get file timestamps as potential fallbacks
    local file_mtime
    file_mtime=$(date -r "$file" "+%Y:%m:%d %H:%M:%S" 2>/dev/null)
    
    # Try to get creation date (birth time) - different syntax for different OSes
    local file_ctime=""
    
    # Linux with stat supporting birth time
    if stat --help 2>&1 | grep -q "birth"; then
      file_ctime=$(stat -c %w "$file" 2>/dev/null | xargs -I{} date -d {} "+%Y:%m:%d %H:%M:%S" 2>/dev/null)
    fi
    
    # macOS and BSD
    if [[ -z "$file_ctime" ]]; then
      file_ctime=$(stat -f %B "$file" 2>/dev/null | xargs -I{} date -r {} "+%Y:%m:%d %H:%M:%S" 2>/dev/null)
    fi
    
    # If we didn't get a creation time, fall back to modification time
    if [[ -z "$file_ctime" ]]; then
      file_ctime="$file_mtime"
    fi
    
    # Choose the oldest date between EXIF date, file mod time, and file creation time
    if [[ -n "$determined_date" ]]; then
      # Convert all dates to seconds since epoch for comparison
      local exif_seconds
      local mtime_seconds
      local ctime_seconds
      
      # Convert EXIF date to seconds
      exif_seconds=$(date -d "$determined_date" +%s 2>/dev/null || date -j -f "%Y:%m:%d %H:%M:%S" "$determined_date" +%s 2>/dev/null)
      
      # Convert file mod time to seconds
      mtime_seconds=$(date -d "$file_mtime" +%s 2>/dev/null || date -j -f "%Y:%m:%d %H:%M:%S" "$file_mtime" +%s 2>/dev/null)
      
      # Convert file creation time to seconds
      ctime_seconds=$(date -d "$file_ctime" +%s 2>/dev/null || date -j -f "%Y:%m:%d %H:%M:%S" "$file_ctime" +%s 2>/dev/null)
      
      # Find the oldest date
      if [[ -n "$mtime_seconds" && -n "$exif_seconds" && "$mtime_seconds" -lt "$exif_seconds" ]]; then
        determined_date="$file_mtime"
        date_source="file_mtime"
      fi
      
      if [[ -n "$ctime_seconds" && -n "$date_source" && "$ctime_seconds" -lt "$mtime_seconds" && "$ctime_seconds" -lt "$exif_seconds" ]]; then
        determined_date="$file_ctime"
        date_source="file_ctime"
      fi
    else
      # No EXIF date found, use file timestamp (older of mtime/ctime)
      local mtime_seconds
      local ctime_seconds
      
      # Convert timestamps to seconds for comparison
      mtime_seconds=$(date -d "$file_mtime" +%s 2>/dev/null || date -j -f "%Y:%m:%d %H:%M:%S" "$file_mtime" +%s 2>/dev/null)
      ctime_seconds=$(date -d "$file_ctime" +%s 2>/dev/null || date -j -f "%Y:%m:%d %H:%M:%S" "$file_ctime" +%s 2>/dev/null)
      
      if [[ -n "$ctime_seconds" && -n "$mtime_seconds" && "$ctime_seconds" -lt "$mtime_seconds" ]]; then
        determined_date="$file_ctime"
        date_source="file_ctime"
      else
        determined_date="$file_mtime"
        date_source="file_mtime"
      fi
    fi
    
    # Add DateTimeOriginal to the destination file
    if [[ -n "$determined_date" ]]; then
      log "DEBUG" "Adding DateTimeOriginal=$determined_date to $dest_file (source: $date_source)"
      if ! exiftool -overwrite_original "-DateTimeOriginal=$determined_date" "$dest_file" >/dev/null 2>&1; then
        log "WARNING" "Failed to add DateTimeOriginal to $dest_file"
      fi
    else
      log "WARNING" "Could not determine a date for $file"
    fi
  else
    log "DEBUG" "DateTimeOriginal already exists in $file"
  fi
}

# Function to extract date from EXIF data
extract_date() {
  local file="$1"
  local exif_date=""
  
  # Check multiple EXIF date fields in priority order
  for date_tag in "DateTimeOriginal" "CreateDate" "DateCreated" "MediaCreateDate" "DateTime"; do
    exif_date=$(exiftool -s3 -"$date_tag" "$file" 2>/dev/null)
    if [[ -n "$exif_date" ]]; then
      break
    fi
  done
  
  # Get file modification date as a fallback
  local file_mod_date
  file_mod_date=$(date -r "$file" +"%Y:%m:%d")
  
  # Try to get creation date (birth time) - different syntax for different OSes
  local file_creation_date=""
  
  # Linux with stat supporting birth time
  if stat --help 2>&1 | grep -q "birth"; then
    file_creation_date=$(stat -c %w "$file" 2>/dev/null | xargs -I{} date -d {} "+%Y:%m:%d" 2>/dev/null)
  fi
  
  # macOS and BSD
  if [[ -z "$file_creation_date" ]]; then
    file_creation_date=$(stat -f %B "$file" 2>/dev/null | xargs -I{} date -r {} "+%Y:%m:%d" 2>/dev/null)
  fi
  
  # If we couldn't get creation date, use modification date
  if [[ -z "$file_creation_date" ]]; then
    file_creation_date="$file_mod_date"
  fi
  
  # Find the oldest date between EXIF, modification, and creation dates
  if [[ -n "$exif_date" ]]; then
    # Extract just the date part from exif_date (YYYY:MM:DD)
    local exif_date_only
    exif_date_only=$(echo "$exif_date" | awk '{print $1}')
    
    # Convert dates to numbers (YYYYMMDD) for comparison
    local exif_date_num file_mod_num file_creation_num
    exif_date_num=$(echo "$exif_date_only" | tr -d ':')
    file_mod_num=$(echo "$file_mod_date" | tr -d ':')
    file_creation_num=$(echo "$file_creation_date" | tr -d ':')
    
    # Start with EXIF date
    local date_to_use="$exif_date_only"
    local date_source="EXIF"
    
    # If mod date is older than current date_to_use, use mod date
    if [[ -n "$file_mod_num" && "$file_mod_num" -lt "$exif_date_num" ]]; then
      date_to_use="$file_mod_date"
      date_source="file modification date"
    fi
    
    # If creation date is older than current date_to_use, use creation date
    if [[ -n "$file_creation_num" && "$file_creation_num" -lt "$(echo "$date_to_use" | tr -d ':')" ]]; then
      date_to_use="$file_creation_date"
      date_source="file creation date"
    fi
    
    log "DEBUG" "Using $date_source for $file"
    # Extract year and month (YYYY/MM)
    echo "$date_to_use" | cut -d':' -f1-2 | tr ':' '/'
  else
    # No EXIF date found, use older of file modification or creation date
    local date_to_use
    local date_source
    
    # Convert dates to numbers (YYYYMMDD) for comparison
    local file_mod_num file_creation_num
    file_mod_num=$(echo "$file_mod_date" | tr -d ':')
    file_creation_num=$(echo "$file_creation_date" | tr -d ':')
    
    if [[ -n "$file_creation_num" && "$file_creation_num" -lt "$file_mod_num" ]]; then
      date_to_use="$file_creation_date"
      date_source="file creation date"
    else
      date_to_use="$file_mod_date"
      date_source="file modification date"
    fi
    
    log "DEBUG" "No EXIF date found for $file, using $date_source"
    # Extract year and month (YYYY/MM)
    echo "$date_to_use" | cut -d':' -f1-2 | tr ':' '/'
  fi
}

# Function to extract camera model from EXIF data
extract_camera() {
  local file="$1"
  
  # Try to get the camera make and model
  local make
  local model
  
  make=$(exiftool -s3 -Make "$file" 2>/dev/null)
  model=$(exiftool -s3 -Model "$file" 2>/dev/null)
  
  if [[ -n "$make" && -n "$model" ]]; then
    echo "${make}_${model}" | tr ' ' '_'
  elif [[ -n "$model" ]]; then
    echo "${model}" | tr ' ' '_'
  elif [[ -n "$make" ]]; then
    echo "${make}" | tr ' ' '_'
  else
    echo "Unknown_Camera"
  fi
}

# Function to determine the destination path for a file
get_destination_path() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  
  case "$ORGANIZE_BY" in
    "date")
      local date
      date=$(extract_date "$file")
      echo "${OUTPUT_DIR}/${date}/${filename}"
      ;;
    "camera")
      local camera
      camera=$(extract_camera "$file")
      echo "${OUTPUT_DIR}/${camera}/${filename}"
      ;;
    "both")
      local date
      local camera
      date=$(extract_date "$file")
      camera=$(extract_camera "$file")
      echo "${OUTPUT_DIR}/${camera}/${date}/${filename}"
      ;;
    *)
      log "ERROR" "Invalid organization type: $ORGANIZE_BY"
      return 1
      ;;
  esac
}

# Function to process a single file
process_file() {
  local file="$1"
  
  # Check if the file is a supported image type
  local file_ext
  file_ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')
  
  # List of known image extensions
  local img_exts=("jpg" "jpeg" "png" "gif" "tiff" "tif" "heic" "heif" "dng" "cr2" "nef" "arw" "raw" "bmp")
  
  # Check if the file extension is in our list of image extensions
  local is_image=false
  for ext in "${img_exts[@]}"; do
    if [[ "$file_ext" == "$ext" ]]; then
      is_image=true
      break
    fi
  done
  
  # If not in our extension list, try mime type as a fallback
  if [[ "$is_image" == "false" ]]; then
    if exiftool -fast -FileMimeType "$file" 2>/dev/null | grep -q "image/"; then
      is_image=true
    fi
  fi
  
  if [[ "$is_image" == "false" ]]; then
    log "DEBUG" "Skipping non-image file: $file"
    return 0
  fi
  
  local dest_path
  dest_path=$(get_destination_path "$file")
  
  if [[ $? -ne 0 || -z "$dest_path" ]]; then
    log "ERROR" "Failed to determine destination for: $file"
    return 1
  fi
  
  local dest_dir
  dest_dir=$(dirname "$dest_path")
  
  # Create destination directory
  if ! create_directory "$dest_dir"; then
    return 1
  fi
  
  # Check if destination file already exists
  if [[ -f "$dest_path" ]]; then
    if cmp -s "$file" "$dest_path"; then
      log "DEBUG" "File already exists (identical): $dest_path"
      return 0
    else
      # File exists but is different - rename by adding timestamp
      local timestamp
      timestamp=$(date +"%Y%m%d%H%M%S")
      local base ext
      base="${dest_path%.*}"
      ext="${dest_path##*.}"
      dest_path="${base}_${timestamp}.${ext}"
      log "WARNING" "File renamed to avoid overwrite: $dest_path"
    fi
  fi
  
  # Copy or move the file
  if [[ "$DRY_RUN" = true ]]; then
    if [[ "$COPY_MODE" = true ]]; then
      log "INFO" "Would copy: $file -> $dest_path"
    else
      log "INFO" "Would move: $file -> $dest_path"
    fi
  else
    # Get file's original timestamps before copying/moving
    local file_mtime
    file_mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    
    # Determine the timestamp to use for the destination file
    local target_time="$file_mtime"
    
    # Try to get EXIF creation date timestamp
    local exif_timestamp=""
    for date_tag in "DateTimeOriginal" "CreateDate" "DateCreated" "MediaCreateDate" "DateTime"; do
      exif_timestamp=$(exiftool -s3 -"$date_tag" -d %s "$file" 2>/dev/null)
      if [[ -n "$exif_timestamp" ]]; then
        # Use the EXIF timestamp if it's older than the file modification time
        if [[ "$exif_timestamp" -lt "$file_mtime" ]]; then
          target_time="$exif_timestamp"
          log "DEBUG" "Using EXIF date ($exif_timestamp) for file timestamp"
        fi
        break
      fi
    done
    
    if [[ "$COPY_MODE" = true ]]; then
      if cp "$file" "$dest_path"; then
        # Preserve original timestamp on the copied file
        if ! touch -m -d "@$target_time" "$dest_path" 2>/dev/null; then
          # Try alternative touch syntax if the first one fails
          touch -m -t "$(date -d "@$target_time" "+%Y%m%d%H%M.%S" 2>/dev/null || date -r "$target_time" "+%Y%m%d%H%M.%S")" "$dest_path" 2>/dev/null
        fi
        
        # Update EXIF DateTimeOriginal if it's missing
        update_exif_date "$file" "$dest_path"
        
        log "DEBUG" "Copied: $file -> $dest_path (preserved timestamp)"
      else
        log "ERROR" "Failed to copy: $file -> $dest_path"
        return 1
      fi
    else
      if mv "$file" "$dest_path"; then
        # For move operations, we may still need to adjust timestamp on some filesystems
        if ! touch -m -d "@$target_time" "$dest_path" 2>/dev/null; then
          # Try alternative touch syntax if the first one fails
          touch -m -t "$(date -d "@$target_time" "+%Y%m%d%H%M.%S" 2>/dev/null || date -r "$target_time" "+%Y%m%d%H%M.%S")" "$dest_path" 2>/dev/null
        fi
        
        # Update EXIF DateTimeOriginal if it's missing
        update_exif_date "$file" "$dest_path"
        
        log "DEBUG" "Moved: $file -> $dest_path (preserved timestamp)"
      else
        log "ERROR" "Failed to move: $file -> $dest_path"
        return 1
      fi
    fi
  fi
  
  return 0
}

# Function to process a batch of files in parallel
process_files_parallel() {
  local files=("$@")
  local pids=()
  local results=()
  local active_jobs=0
  local file_index=0
  local total_files=${#files[@]}
  local processed=0
  local errors=0
  local last_percent=-1
  local silent
  if [[ -t 1 ]]; then
    silent=""
  else
    silent="true"
  fi
  
  # Create temporary directory for job status files
  local tmp_dir
  tmp_dir=$(mktemp -d)
  
  log "DEBUG" "Starting parallel processing of $total_files files with max $MAX_JOBS jobs"
  
  # Process files in batches
  while [[ $file_index -lt $total_files || ${#pids[@]} -gt 0 ]]; do
    # Start new jobs if we have files to process and slots available
    while [[ $file_index -lt $total_files && $active_jobs -lt $MAX_JOBS ]]; do
      local file="${files[$file_index]}"
      local status_file="${tmp_dir}/job_${file_index}.status"
      
      # Start background job to process the file
      (
        if process_file "$file"; then
          echo "success" > "$status_file"
        else
          echo "error" > "$status_file"
        fi
      ) &
      
      # Store the process ID
      pids+=($!)
      results+=("$status_file")
      ((active_jobs++))
      ((file_index++))
      
      log "DEBUG" "Started job for: $file (pid: ${pids[-1]}, active: $active_jobs)"
    done
    
    # Wait for any job to complete (non-blocking)
    if [[ ${#pids[@]} -gt 0 ]]; then
      for i in "${!pids[@]}"; do
        if ! kill -0 "${pids[$i]}" 2>/dev/null; then
          # Job completed
          wait "${pids[$i]}" 2>/dev/null
          
          # Check the result
          if [[ -f "${results[$i]}" ]]; then
            local status
            status=$(cat "${results[$i]}")
            if [[ "$status" == "success" ]]; then
              ((processed++))
            else
              ((errors++))
            fi
          else
            ((errors++))
          fi
          
          # Remove the job from the active list
          unset "pids[$i]"
          unset "results[$i]"
          ((active_jobs--))
          
          # Update progress bar
          if [[ $total_files -gt 0 && "$silent" != "true" ]]; then
            local percent=$((100 * (processed + errors) / total_files))
            if [[ $percent -ne $last_percent ]]; then
              draw_progress_bar "$percent" "$((processed + errors))" "$total_files"
              last_percent=$percent
            fi
          fi
          
          # Print detailed progress every 10 files if verbose
          if [[ $VERBOSE = true && $((processed + errors)) -gt 0 && $(((processed + errors) % 10)) -eq 0 ]]; then
            log "INFO" "Progress: $((100 * (processed + errors) / total_files))% ($((processed + errors))/$total_files files processed)"
          fi
          
          break  # Only process one completed job at a time
        fi
      done
      
      # Reindex the arrays after removing elements
      pids=("${pids[@]}")
      results=("${results[@]}")
      
      # Short sleep to avoid CPU spinning
      sleep 0.1
    fi
  done
  
  # Clean up
  rm -rf "$tmp_dir"
  
  # Complete the progress bar and add a newline
  if [[ $total_files -gt 0 && "$silent" != "true" ]]; then
    draw_progress_bar 100 "$total_files" "$total_files"
    echo
  fi
  
  log "INFO" "Parallel processing completed: $processed successful, $errors failed"
  return 0
}

# Function to process files in a directory
process_directory() {
  local dir="$1"
  local count=0
  local errors=0
  
  if [[ ! -d "$dir" ]]; then
    log "ERROR" "Directory does not exist: $dir"
    return 1
  fi
  
  log "INFO" "Processing directory: $dir"
  
  # Build a list of files to process
  local files=()
  
  if [[ "$RECURSIVE" = true ]]; then
    # Get files recursively
    while IFS= read -r -d '' file; do
      if [[ -f "$file" ]]; then
        files+=("$file")
      fi
    done < <(find "$dir" -type f -print0)
  else
    # Get only files in the current directory
    for file in "$dir"/*; do
      if [[ -f "$file" ]]; then
        files+=("$file")
      fi
    done
  fi
  
  local total_files=${#files[@]}
  log "INFO" "Found $total_files files to process"
  
  if [[ $total_files -eq 0 ]]; then
    log "WARNING" "No files found to process"
    return 0
  fi
  
  if [[ "$PARALLEL" = true && $total_files -gt 1 ]]; then
    # Process files in parallel
    log "INFO" "Using parallel processing with up to $MAX_JOBS jobs"
    process_files_parallel "${files[@]}"
  else
    # Process files sequentially
    log "INFO" "Using sequential processing"
    local last_percent=-1
    local silent
    if [[ -t 1 ]]; then
      silent=""
    else
      silent="true"
    fi
    
    for file in "${files[@]}"; do
      if process_file "$file"; then
        ((count++))
      else
        ((errors++))
      fi
      
      # Update progress bar
      if [[ $total_files -gt 0 && "$silent" != "true" ]]; then
        local percent=$((100 * (count + errors) / total_files))
        if [[ $percent -ne $last_percent ]]; then
          draw_progress_bar "$percent" "$((count + errors))" "$total_files"
          last_percent=$percent
        fi
      fi
      
      # Print detailed progress every 10 files if verbose
      if [[ $VERBOSE = true && $((count + errors)) -gt 0 && $(((count + errors) % 10)) -eq 0 ]]; then
        log "INFO" "Progress: $(((count + errors) * 100 / total_files))% ($((count + errors))/$total_files files processed)"
      fi
    done
    
    # Complete the progress bar and add a newline
    if [[ $total_files -gt 0 && "$silent" != "true" ]]; then
      draw_progress_bar 100 "$total_files" "$total_files"
      echo
    fi
    
    log "INFO" "Processed $count files from $dir ($errors errors)"
  fi
  
  return 0
}

# Main function
main() {
  
  # Parse command line arguments
  local source_dir=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -b|--organize-by)
        ORGANIZE_BY="$2"
        if [[ "$ORGANIZE_BY" != "date" && "$ORGANIZE_BY" != "camera" && "$ORGANIZE_BY" != "both" ]]; then
          log "ERROR" "Invalid organization type: $ORGANIZE_BY"
          show_usage
          exit 1
        fi
        shift 2
        ;;
      -m|--move)
        COPY_MODE=false
        shift
        ;;
      -d|--dry-run)
        DRY_RUN=true
        shift
        ;;
      -r|--recursive)
        RECURSIVE=true
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -p|--parallel)
        PARALLEL=true
        shift
        ;;
      -s|--sequential)
        PARALLEL=false
        shift
        ;;
      -j|--jobs)
        MAX_JOBS="$2"
        if ! [[ "$MAX_JOBS" =~ ^[0-9]+$ ]] || [ "$MAX_JOBS" -lt 1 ]; then
          log "ERROR" "Number of jobs must be a positive integer"
          show_usage
          exit 1
        fi
        shift 2
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      --version)
        show_version
        exit 0
        ;;
      -*)
        log "ERROR" "Unknown option: $1"
        show_usage
        exit 1
        ;;
      *)
        if [[ -z "$source_dir" ]]; then
          source_dir="$1"
        else
          log "ERROR" "Only one source directory can be specified"
          show_usage
          exit 1
        fi
        shift
        ;;
    esac
  done
  
  # Validate source directory
  if [[ -z "$source_dir" ]]; then
    log "ERROR" "Source directory is required"
    show_usage
    exit 1
  fi
  
  if [[ ! -d "$source_dir" ]]; then
    log "ERROR" "Source directory does not exist: $source_dir"
    exit 1
  fi
  
  # Check dependencies before processing files
  check_dependencies
  
  # Get absolute paths
  SOURCE_DIR=$(realpath "$source_dir")
  OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
  
  # Prevent source and destination from being the same
  if [[ "$SOURCE_DIR" == "$OUTPUT_DIR" ]]; then
    log "ERROR" "Source and destination directories cannot be the same"
    exit 1
  fi
  
  # Display configuration
  log "INFO" "$SCRIPT_NAME v$SCRIPT_VERSION"
  log "INFO" "Source directory: $SOURCE_DIR"
  log "INFO" "Output directory: $OUTPUT_DIR"
  log "INFO" "Organization: $ORGANIZE_BY"
  log "INFO" "Mode: $([ "$COPY_MODE" = true ] && echo "copy" || echo "move")"
  log "INFO" "Recursive: $([ "$RECURSIVE" = true ] && echo "yes" || echo "no")"
  log "INFO" "Dry run: $([ "$DRY_RUN" = true ] && echo "yes" || echo "no")"
  if [[ "$PARALLEL" = true ]]; then
    log "INFO" "Parallel processing: yes (using $MAX_JOBS CPU cores)"
  else
    log "INFO" "Parallel processing: no (available CPU cores: $MAX_JOBS)"
  fi
  
  # Process the source directory
  if process_directory "$SOURCE_DIR"; then
    log "INFO" "Photo organization completed successfully"
    return 0
  else
    log "ERROR" "Photo organization completed with errors"
    return 1
  fi
}

# Run the script
main "$@"