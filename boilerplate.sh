#!/bin/bash

# =============================================================================
# Script Name: script_template.sh
# Description: A robust, user-friendly shell script template with interactive
#              select menus and comprehensive error handling.
# Author: Joshua McKenna
# Date: 2025-01-24
# =============================================================================

# -------------------------------
# 1. Configuration and Initialization
# -------------------------------

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Define color codes for output
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
RESET='\033[0m'

# Define global variables
source "$(dirname "$0")/config.env"
NOW=$(date '+%F %H.%M.%S')
LOG_FILE="${LOG_DIR}/$NOW.log"

# -------------------------------
# 2. Utility Functions
# -------------------------------

# Function: print_error
# Description: Prints error messages in bold red.
print_error() {
    echo -e "${BOLD_RED}ERROR${RESET}: $1" >&2
}

# Function: print_warning
# Description: Prints warning messages in bold yellow.
print_warning() {
    echo -e "${BOLD_YELLOW}WARNING${RESET}: $1"
}

# Function: print_info
# Description: Prints informational messages in bold blue.
print_info() {
    echo -e "${BOLD_BLUE}INFO${RESET}: $1"
}

# Function: print_success
# Description: Prints success messages in bold green.
print_success() {
    echo -e "${BOLD_GREEN}SUCCESS${RESET}: $1"
}

# Function: print_and_execute
# Description: Prints the command before executing it.
print_and_execute() {
    echo -e "${BOLD_BLUE}+ $*${RESET}" | tee -a "$LOG_FILE"
    "$@" | tee -a "$LOG_FILE"
}

# Function: validate_dependencies
# Description: Checks if required commands are available.
validate_dependencies() {
    local dependencies=("select" "uname" "date")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            print_error "Required command '$cmd' is not installed. Exiting."
            exit 1
        fi
    done
}

# Function: detect_platform
# Description: Detects the operating system and sets the TIMEOUT command accordingly.
detect_platform() {
    if [ "$(uname -s)" == "Linux" ]; then
        TIMEOUT_CMD="timeout -v $RUN_TIME_LIMIT"
    elif [ "$(uname -s)" == "Darwin" ]; then
        if command -v gtimeout &>/dev/null; then
            TIMEOUT_CMD="gtimeout -v $RUN_TIME_LIMIT"
        else
            print_warning "gtimeout not available. Install it using 'brew install coreutils' to enforce time limits."
            TIMEOUT_CMD=""
        fi
    else
        print_warning "Unsupported OS. TIMEOUT functionality may not work as expected."
        TIMEOUT_CMD=""
    fi
}

# Function: initialize_logging
# Description: Initializes the log file.
initialize_logging() {
    echo "===== Script Started at $(date) =====" >"$LOG_FILE"
}

# -------------------------------
# 3. Task Functions
# -------------------------------

# Function: task_exit
# Description: Exits the script.
task_exit() {
    print_info "Exiting program."
    exit 0
}

# Function: task_find_even_multiples
# Description: Finds even multiples of a given number.
task_find_even_multiples() {
    echo "Executing Task 1: Find the even multiples of any number."
    # Placeholder for actual task implementation
    # Example:
    read -p "Enter a number: " number
    if ! [[ "$number" =~ ^-?[0-9]+$ ]]; then
        print_error "Invalid input. Please enter a valid integer."
        return 1
    fi
    echo "Even multiples of $number up to 100:"
    for ((i = 1; i <= 100; i++)); do
        multiple=$((number * i))
        if ((multiple % 2 == 0)); then
            echo "$multiple"
        fi
    done
}

# Function: task_find_linear_sequence
# Description: Finds terms of a linear sequence given the rule Un=an+b.
task_find_linear_sequence() {
    echo "Executing Task 2: Find the terms of any linear sequence given the rule Un=an+b."
    # Placeholder for actual task implementation
    # Example:
    read -p "Enter the value of 'a': " a
    read -p "Enter the value of 'b': " b
    read -p "Enter the number of terms: " n
    if ! [[ "$a" =~ ^-?[0-9]+$ && "$b" =~ ^-?[0-9]+$ && "$n" =~ ^-?[0-9]+$ ]]; then
        print_error "Invalid input. Please enter valid integers for a, b, and n."
        return 1
    fi
    echo "First $n terms of the sequence Un = $a*n + $b:"
    for ((i = 1; i <= n; i++)); do
        term=$((a * i + b))
        echo "U$i = $term"
    done
}

# Function: task_find_product_numbers
# Description: Finds numbers that can be expressed as the product of two nonnegative integers in succession and prints them in increasing order.
task_find_product_numbers() {
    echo "Executing Task 3: Find the numbers that can be expressed as the product of two nonnegative integers in succession and print them in increasing order."
    # Placeholder for actual task implementation
    # Example:
    read -p "Enter the maximum number to check: " max
    if ! [[ "$max" =~ ^-?[0-9]+$ ]]; then
        print_error "Invalid input. Please enter a valid integer."
        return 1
    fi
    echo "Numbers up to $max that are products of two consecutive nonnegative integers:"
    for ((i = 0; i * i + i <= max; i++)); do
        product=$((i * (i + 1)))
        if ((product <= max)); then
            echo "$product"
        fi
    done
}

# -------------------------------
# 4. Menu Setup
# -------------------------------

# Define menu options
choices=(
    "Exit program"
    "Find the even multiples of any number."
    "Find the terms of any linear sequence given the rule Un=an+b."
    "Find the numbers that can be expressed as the product of two nonnegative integers in succession and print them in increasing order."
)

# Set the prompt
PS3="Please select one of the options: "

# -------------------------------
# 5. Main Menu Function
# -------------------------------

main_menu() {
    select choice in "${choices[@]}"; do
        case "$choice" in
        "${choices[0]}")
            task_exit
            ;;
        "${choices[1]}")
            task_find_even_multiples
            break
            ;;
        "${choices[2]}")
            task_find_linear_sequence
            break
            ;;
        "${choices[3]}")
            task_find_product_numbers
            break
            ;;
        *)
            print_error "Invalid selection, please try again."
            ;;
        esac
    done
}

# -------------------------------
# 6. Script Entry Point
# -------------------------------

# Validate dependencies
validate_dependencies

# Initialize logging
initialize_logging

# Detect platform for TIMEOUT command
detect_platform

# Optional: Set a run time limit (in seconds)
RUN_TIME_LIMIT=60 # Adjust as needed

# Display the menu and handle user selection
while true; do
    main_menu
    echo
    read -p "Would you like to perform another operation? (y/n): " yn
    case "$yn" in
    [Yy]*) ;;
    [Nn]*) task_exit ;;
    *) print_warning "Please answer yes or no." ;;
    esac
done

# End of script
