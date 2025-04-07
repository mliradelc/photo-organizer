#!/bin/bash
#
# Photo Organizer - A tool to organize photos based on EXIF metadata
# 

set -e

# Constants
readonly SCRIPT_NAME="Photo Organizer"
readonly SCRIPT_VERSION="1.0.0"

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
  
  if [[ -n "$exif_date" ]]; then
    # Extract just the date part from exif_date (YYYY:MM:DD)
    local exif_date_only
    exif_date_only=$(echo "$exif_date" | awk '{print $1}')
    
    # Compare dates - if file_mod_date is older than exif_date, use file_mod_date
    # Convert dates to numbers (YYYYMMDD) for comparison
    local exif_num file_mod_num
    exif_num=$(echo "$exif_date_only" | tr -d ':')
    file_mod_num=$(echo "$file_mod_date" | tr -d ':')
    
    if [[ "$file_mod_num" -lt "$exif_num" ]]; then
      log "DEBUG" "File mod date ($file_mod_date) is older than EXIF date ($exif_date_only), using file mod date"
      # Extract year and month (YYYY/MM)
      echo "$file_mod_date" | cut -d':' -f1-2 | tr ':' '/'
    else
      # Use EXIF date (it's newer or the same)
      # Extract year and month (YYYY/MM)
      echo "$exif_date_only" | cut -d':' -f1-2 | tr ':' '/'
    fi
  else
    # No EXIF date found, use file modification date
    log "DEBUG" "No EXIF date found for $file, using file modification date"
    # Extract year and month (YYYY/MM)
    echo "$file_mod_date" | cut -d':' -f1-2 | tr ':' '/'
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
    if [[ "$COPY_MODE" = true ]]; then
      if cp "$file" "$dest_path"; then
        log "DEBUG" "Copied: $file -> $dest_path"
      else
        log "ERROR" "Failed to copy: $file -> $dest_path"
        return 1
      fi
    else
      if mv "$file" "$dest_path"; then
        log "DEBUG" "Moved: $file -> $dest_path"
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
          
          # Print progress every 10 files
          if [[ $((processed + errors)) -gt 0 && $(((processed + errors) % 10)) -eq 0 ]]; then
            log "INFO" "Progress: $(((processed + errors) * 100 / total_files))% ($((processed + errors))/$total_files files processed)"
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
    for file in "${files[@]}"; do
      if process_file "$file"; then
        ((count++))
      else
        ((errors++))
      fi
      
      # Print progress every 10 files
      if [[ $((count + errors)) -gt 0 && $(((count + errors) % 10)) -eq 0 ]]; then
        log "INFO" "Progress: $(((count + errors) * 100 / total_files))% ($((count + errors))/$total_files files processed)"
      fi
    done
    
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