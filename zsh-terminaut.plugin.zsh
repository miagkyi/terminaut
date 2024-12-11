#!/usr/bin/env zsh

# Check if required dependencies are installed
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required but not installed"
    return 1
fi

if [[ -z "${OPENAI_API_KEY}" ]]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    return 1
fi

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Loading spinner function
function show_spinner() {
    local pid=$1
    local frames=(
        "🤖 ..."
        "🤖 .•."
        "🤖 •.•"
        "🤖 .•."
        "🤖 ..."
        "🤖 💭"
        "🤖 ✨"
        "🤖 💡"
    )
    local i=0
    tput civis  # Hide cursor
    while kill -0 $pid 2>/dev/null; do
        printf "\r${frames[$i]} "
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.15
    done
    printf "\r"
    tput cnorm  # Show cursor
}

# Function to get command suggestion using Python and OpenAI library
function get_command_suggestion() {
    local prompt=$1
    python3 -c "
import os
import sys
from openai import OpenAI

client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

try:
    response = client.chat.completions.create(
        model='gpt-4',
        messages=[
            {
                'role': 'system',
                'content': 'You are a helpful assistant that translates natural language into terminal commands. Respond ONLY with the command, no explanation.'
            },
            {
                'role': 'user',
                'content': '$prompt'
            }
        ]
    )
    print(response.choices[0].message.content)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    exit(1)
"
}

# Main function to handle command translation
function t() {
    if [[ $# -eq 0 ]]; then
        echo -n "${CYAN}$ ${NC}"
        read user_input
    else
        user_input="$*"
    fi
    
    if [[ -n "$user_input" ]]; then
        # Start spinner in background and capture output
        {
            get_command_suggestion "$user_input" > /tmp/cmd_suggestion.$$ 2>/dev/null
        } &!
        local pid=$!
        show_spinner $pid
        wait $pid 2>/dev/null
        
        local suggested_command
        suggested_command=$(<"/tmp/cmd_suggestion.$$")
        rm -f "/tmp/cmd_suggestion.$$"
        
        if [[ -n "$suggested_command" ]]; then
            # Put the command in the input buffer
            print -z "$suggested_command"
        fi
    fi
}