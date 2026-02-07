#!/usr/bin/env bash

# Extended color palette
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[97m'
GRAY='\033[90m'
BRIGHT_GREEN='\033[92m'
BRIGHT_CYAN='\033[96m'
BRIGHT_YELLOW='\033[93m'
DIM='\033[2m'
BOLD='\033[1m'
ITALIC='\033[3m'
RESET='\033[0m'
BG_BLACK='\033[40m'
BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_CYAN='\033[46m'

# Setup
trap 'tput cnorm; clear; exit' INT TERM
tput civis
clear

cols=$(tput cols)
lines=$(tput lines)
cx=$((cols / 2))
cy=$((lines / 2))

pos() { printf "\033[%d;%dH" "$1" "$2"; }
pause() { sleep "$1"; }

# Box drawing characters
BOX_TL="╭"
BOX_TR="╮"
BOX_BL="╰"
BOX_BR="╯"
BOX_H="─"
BOX_V="│"
BOX_T="┬"
BOX_B="┴"
BOX_L="├"
BOX_R="┤"
BOX_X="┼"

# Double line variants
DBL_TL="╔"
DBL_TR="╗"
DBL_BL="╚"
DBL_BR="╝"
DBL_H="═"
DBL_V="║"

# Draw styled box with rounded corners
draw_panel() {
    local y=$1 x=$2 h=$3 w=$4 title=$5 color=${6:-$CYAN}
    local y2=$((y + h - 1))
    local x2=$((x + w - 1))
    
    # Corners
    pos "$y" "$x"; printf "${color}${BOX_TL}${RESET}"
    pos "$y" "$x2"; printf "${color}${BOX_TR}${RESET}"
    pos "$y2" "$x"; printf "${color}${BOX_BL}${RESET}"
    pos "$y2" "$x2"; printf "${color}${BOX_BR}${RESET}"
    
    # Horizontal lines
    for ((i=x+1; i<x2; i++)); do
        pos "$y" "$i"; printf "${color}${BOX_H}${RESET}"
        pos "$y2" "$i"; printf "${color}${BOX_H}${RESET}"
    done
    
    # Vertical lines
    for ((i=y+1; i<y2; i++)); do
        pos "$i" "$x"; printf "${color}${BOX_V}${RESET}"
        pos "$i" "$x2"; printf "${color}${BOX_V}${RESET}"
    done
    
    # Title
    if [ -n "$title" ]; then
        pos "$y" $((x + 2))
        printf "${color}┤ ${WHITE}${BOLD}%s${RESET}${color} ├${RESET}" "$title"
    fi
}

# Animated spinner
spinner() {
    local frames=('/' '-' '\' '|')
    printf "%s" "${frames[$((RANDOM % 4))]}"
}

# Draw a graph node with glow effect
draw_node() {
    local y=$1 x=$2 label=$3 state=$4  # state: dim, active, pulse, owned
    local w=$((${#label} + 4))
    local left=$((x - w/2))
    local hbar=""
    
    for ((i=0; i<w-2; i++)); do hbar="${hbar}${BOX_H}"; done
    
    case "$state" in
        dim)
            pos $((y-1)) $left; printf "${GRAY}${BOX_TL}%s${BOX_TR}${RESET}" "$hbar"
            pos $y $left; printf "${GRAY}${BOX_V} ${DIM}%s${RESET}${GRAY} ${BOX_V}${RESET}" "$label"
            pos $((y+1)) $left; printf "${GRAY}${BOX_BL}%s${BOX_BR}${RESET}" "$hbar"
            ;;
        active)
            pos $((y-1)) $left; printf "${CYAN}${BOX_TL}%s${BOX_TR}${RESET}" "$hbar"
            pos $y $left; printf "${CYAN}${BOX_V}${RESET} ${WHITE}%s${RESET} ${CYAN}${BOX_V}${RESET}" "$label"
            pos $((y+1)) $left; printf "${CYAN}${BOX_BL}%s${BOX_BR}${RESET}" "$hbar"
            ;;
        pulse)
            pos $((y-1)) $left; printf "${BRIGHT_CYAN}${DBL_TL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_TR}${RESET}"
            pos $y $left; printf "${BRIGHT_CYAN}${DBL_V}${RESET} ${BOLD}${WHITE}%s${RESET} ${BRIGHT_CYAN}${DBL_V}${RESET}" "$label"
            pos $((y+1)) $left; printf "${BRIGHT_CYAN}${DBL_BL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_BR}${RESET}"
            ;;
        owned)
            pos $((y-1)) $left; printf "${GREEN}${DBL_TL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_TR}${RESET}"
            pos $y $left; printf "${GREEN}${DBL_V}${RESET} ${BRIGHT_GREEN}${BOLD}%s${RESET} ${GREEN}${DBL_V}${RESET}" "$label"
            pos $((y+1)) $left; printf "${GREEN}${DBL_BL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_BR}${RESET}"
            ;;
        target)
            pos $((y-1)) $left; printf "${YELLOW}${DBL_TL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_TR}${RESET}"
            pos $y $left; printf "${YELLOW}${DBL_V}${RESET} ${BRIGHT_YELLOW}${BOLD}%s${RESET} ${YELLOW}${DBL_V}${RESET}" "$label"
            pos $((y+1)) $left; printf "${YELLOW}${DBL_BL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_BR}${RESET}"
            ;;
    esac
}

# Draw edge between nodes (horizontal)
draw_h_edge() {
    local y=$1 x1=$2 x2=$3 state=$4
    local char="-"
    local color=$GRAY
    
    case "$state" in
        dim) color=$GRAY; char="-" ;;
        active) color=$CYAN; char="-" ;;
        data) color=$GREEN; char="=" ;;
    esac
    
    for ((x=x1; x<=x2; x++)); do
        pos $y $x
        printf "${color}%s${RESET}" "$char"
    done
}

# Draw edge with arrow
draw_edge_arrow() {
    local y=$1 x1=$2 x2=$3 state=$4
    local color=$GRAY
    case "$state" in
        dim) color=$GRAY ;;
        active) color=$CYAN ;;
        data) color=$GREEN ;;
    esac
    
    for ((x=x1; x<x2; x++)); do
        pos $y $x; printf "${color}─${RESET}"
    done
    pos $y $x2; printf "${color}▶${RESET}"
}

# Animated data packet traveling along edge
animate_packet() {
    local y=$1 x1=$2 x2=$3
    for ((x=x1; x<=x2; x++)); do
        pos $y $x; printf "${BRIGHT_GREEN}●${RESET}"
        pause 0.02
        pos $y $x; printf "${GREEN}─${RESET}"
    done
}

# Progress bar with percentage
draw_progress() {
    local y=$1 x=$2 w=$3 pct=$4 label=$5
    local filled=$((pct * w / 100))
    
    pos $y $x
    printf "${DIM}%s ${RESET}" "$label"
    printf "${GRAY}▐${RESET}"
    for ((i=0; i<w; i++)); do
        if [ $i -lt $filled ]; then
            printf "${GREEN}█${RESET}"
        else
            printf "${GRAY}░${RESET}"
        fi
    done
    printf "${GRAY}▌${RESET} ${WHITE}%3d%%${RESET}" "$pct"
}

# Status indicator
status_dot() {
    local y=$1 x=$2 state=$3
    pos $y $x
    case "$state" in
        off) printf "${GRAY}○${RESET}" ;;
        on) printf "${GREEN}●${RESET}" ;;
        warn) printf "${YELLOW}●${RESET}" ;;
        err) printf "${RED}✖${RESET}" ;;
    esac
}

# Log panel with fixed position
log_y=0
log_max=6
declare -a log_buffer
init_log() { log_buffer=(); log_y=0; }
add_log() {
    local msg=$1
    local ts
    ts=$(date '+%H:%M:%S')
    log_buffer+=("${DIM}[$ts]${RESET} $msg")
    if [ ${#log_buffer[@]} -gt $log_max ]; then
        log_buffer=("${log_buffer[@]:1}")
    fi
}
draw_log() {
    local base_y=$1 base_x=$2
    for i in "${!log_buffer[@]}"; do
        pos $((base_y + i)) $base_x
        printf "%-60s" ""
        pos $((base_y + i)) $base_x
        printf "%s" "${log_buffer[$i]}"
    done
}

# =============================================================================
# SCENE 1: Boot sequence
# =============================================================================
clear

# Centered boot text
pos $((cy - 5)) $((cx - 20))
printf "${DIM}Initializing TerminalRally v0.4.2...${RESET}"
pause 0.3

# Animated loading bar
for pct in 0 15 30 45 60 75 90 100; do
    draw_progress $((cy - 3)) $((cx - 20)) 30 $pct "Loading"
    pause 0.08
done

pause 0.3
pos $((cy - 1)) $((cx - 15))
printf "${GREEN}[OK]${RESET} ${WHITE}System ready${RESET}"
pause 0.5

# =============================================================================
# SCENE 2: Main TUI with graph-based proxy chain
# =============================================================================
clear

# Header bar
pos 1 2
printf "${BG_BLUE}${WHITE}${BOLD} TERMINALRALLY ${RESET}${BG_BLACK}${GRAY} v0.4.2 ${RESET}"
pos 1 $((cols - 22))
printf "${GRAY}%s${RESET}" "$(date '+%Y-%m-%d %H:%M:%S')"

# Main border
draw_panel 2 1 $((lines - 2)) $((cols - 1)) "OPERATION NIGHTFALL" "$CYAN"

# Left panel: Network Graph
draw_panel 4 3 16 44 "RELAY CHAIN" "$BLUE"

# Right panel: Targets
draw_panel 4 49 16 $((cols - 51)) "TARGET MATRIX" "$MAGENTA"

# Bottom panel: Activity
draw_panel 21 3 $((lines - 22)) $((cols - 4)) "LIVE FEED" "$GRAY"

init_log

# Graph layout - staggered nodes with connecting edges
# 
#   ╭────────╮
#   │ ORIGIN │
#   ╰───┬────╯
#       │
#       ├────────────╮
#       │            │
#   ╭───┴────╮   ╭───┴────╮
#   │ SOCKS5 │───│  HTTP  │
#   ╰───┬────╯   ╰───┬────╯
#       │            │
#       ╰─────┬──────╯
#             │
#         ╭───┴────╮
#         │ SOCKS4 │
#         ╰───┬────╯
#             │
#         ╭───┴────╮
#         │  EXIT  │──────▶ [TARGET]
#         ╰────────╯

node_positions=(
    "ORIGIN:22:6"
    "SOCKS5:14:9"
    "HTTP:30:9"
    "SOCKS4:22:12"
    "EXIT:22:15"
)
node_ips=("10.0.0.50" "45.33.32.1" "91.121.87.10" "185.220.101.42" "194.88.106.14")

# Draw graph node
draw_graph_node() {
    local label=$1 x=$2 y=$3 state=$4
    local w=$((${#label} + 4))
    local left=$((x - w/2 + 3))  # offset for panel position
    local ypos=$((y))
    
    local hbar=""
    for ((i=0; i<w-2; i++)); do hbar="${hbar}${BOX_H}"; done
    
    case "$state" in
        dim)
            pos $((ypos-1)) $left; printf "${GRAY}${BOX_TL}%s${BOX_TR}${RESET}" "$hbar"
            pos $ypos $left; printf "${GRAY}${BOX_V}${RESET}${DIM} %s ${RESET}${GRAY}${BOX_V}${RESET}" "$label"
            pos $((ypos+1)) $left; printf "${GRAY}${BOX_BL}%s${BOX_BR}${RESET}" "$hbar"
            ;;
        active)
            pos $((ypos-1)) $left; printf "${CYAN}${BOX_TL}%s${BOX_TR}${RESET}" "$hbar"
            pos $ypos $left; printf "${CYAN}${BOX_V}${RESET} ${WHITE}%s${RESET} ${CYAN}${BOX_V}${RESET}" "$label"
            pos $((ypos+1)) $left; printf "${CYAN}${BOX_BL}%s${BOX_BR}${RESET}" "$hbar"
            ;;
        pulse)
            pos $((ypos-1)) $left; printf "${BRIGHT_CYAN}${DBL_TL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_TR}${RESET}"
            pos $ypos $left; printf "${BRIGHT_CYAN}${DBL_V}${RESET} ${BOLD}${WHITE}%s${RESET} ${BRIGHT_CYAN}${DBL_V}${RESET}" "$label"
            pos $((ypos+1)) $left; printf "${BRIGHT_CYAN}${DBL_BL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_BR}${RESET}"
            ;;
        owned)
            pos $((ypos-1)) $left; printf "${GREEN}${DBL_TL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_TR}${RESET}"
            pos $ypos $left; printf "${GREEN}${DBL_V}${RESET} ${BRIGHT_GREEN}${BOLD}%s${RESET} ${GREEN}${DBL_V}${RESET}" "$label"
            pos $((ypos+1)) $left; printf "${GREEN}${DBL_BL}"; for ((i=0;i<w-2;i++)); do printf "${DBL_H}"; done; printf "${DBL_BR}${RESET}"
            ;;
    esac
}

# Draw connecting edges
draw_graph_edges() {
    local state=$1
    local color=$GRAY
    local vchar="${BOX_V}"
    local hchar="${BOX_H}"
    
    case "$state" in
        dim) color=$GRAY ;;
        active) color=$CYAN ;;
        data) color=$GREEN; vchar="║"; hchar="═" ;;
    esac
    
    # ORIGIN down to split
    pos 8 25; printf "${color}${vchar}${RESET}"
    
    # Split left to SOCKS5
    pos 9 17; printf "${color}${BOX_TL}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${BOX_B}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${BOX_TR}${RESET}"
    pos 10 17; printf "${color}${vchar}${RESET}"
    pos 10 33; printf "${color}${vchar}${RESET}"
    
    # Below SOCKS5 and HTTP, merge
    pos 12 17; printf "${color}${BOX_BL}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${BOX_T}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${hchar}${BOX_BR}${RESET}"
    
    # Down to SOCKS4
    pos 13 25; printf "${color}${vchar}${RESET}"
    
    # Down to EXIT
    pos 16 25; printf "${color}${vchar}${RESET}"
    
    # EXIT to TARGET arrow
    pos 17 33; printf "${color}${hchar}${hchar}${hchar}▶${RESET}"
    pos 17 38; printf "${YELLOW}[TGT]${RESET}"
}

# Draw all nodes dim initially
for node_info in "${node_positions[@]}"; do
    IFS=':' read -r label nx ny <<< "$node_info"
    draw_graph_node "$label" "$nx" "$ny" "dim"
done

draw_graph_edges "dim"

# Target list
targets=("192.168.1.100|DC01|SMB" "192.168.1.101|SQL01|MSSQL" "192.168.1.105|WEB01|HTTP" "192.168.1.110|FILE01|SMB")
target_states=("dim" "dim" "dim" "dim")

draw_target_list() {
    pos 6 51
    printf "${DIM}%-15s %-8s %-8s %s${RESET}" "ADDRESS" "HOST" "SVC" "STATUS"
    pos 7 51
    printf "${GRAY}──────────────────────────────────────────${RESET}"
    
    for i in "${!targets[@]}"; do
        IFS='|' read -r ip host svc <<< "${targets[$i]}"
        pos $((8 + i * 2)) 51
        
        case "${target_states[$i]}" in
            dim)
                printf "${GRAY}%-15s %-8s %-8s ${DIM}○${RESET}" "$ip" "$host" "$svc"
                ;;
            scan)
                printf "${CYAN}%-15s %-8s %-8s ${YELLOW}◐${RESET}" "$ip" "$host" "$svc"
                ;;
            vuln)
                printf "${YELLOW}%-15s %-8s %-8s ${YELLOW}⚠${RESET}" "$ip" "$host" "$svc"
                ;;
            owned)
                printf "${GREEN}%-15s %-8s %-8s ${GREEN}✓${RESET}" "$ip" "$host" "$svc"
                ;;
        esac
    done
}

draw_target_list

# Chain status
pos 19 7
printf "${GRAY}Status: ${DIM}INACTIVE${RESET}  ${GRAY}Hops: 0/5  Latency: --${RESET}"

add_log "System initialized"
draw_log 23 5
pause 0.4

# Animate chain building
add_log "Establishing relay chain..."
draw_log 23 5
pause 0.3

node_order=("ORIGIN:22:6" "SOCKS5:14:9" "HTTP:30:9" "SOCKS4:22:12" "EXIT:22:15")

for idx in "${!node_order[@]}"; do
    IFS=':' read -r label nx ny <<< "${node_order[$idx]}"
    
    # Pulse current node
    draw_graph_node "$label" "$nx" "$ny" "pulse"
    pause 0.15
    
    # Set to active
    draw_graph_node "$label" "$nx" "$ny" "active"
    
    # Update status
    pos 19 7
    printf "${CYAN}Status: ${YELLOW}BUILDING${RESET}  ${CYAN}Hops: %d/5${RESET}  ${GRAY}Latency: ${WHITE}%dms${RESET}   " $((idx + 1)) $((200 + RANDOM % 300))
    
    add_log "Connected: $label (${node_ips[$idx]})"
    draw_log 23 5
    pause 0.2
done

# Activate edges
draw_graph_edges "active"

# Chain complete
pos 19 7
printf "${GREEN}Status: ${BRIGHT_GREEN}${BOLD}ACTIVE${RESET}    ${GREEN}Hops: 5/5${RESET}  ${GRAY}Latency: ${WHITE}847ms${RESET}  "

add_log "${GREEN}Relay chain established${RESET}"
draw_log 23 5
pause 0.4

# Scan targets
add_log "Scanning target network..."
draw_log 23 5

for i in "${!targets[@]}"; do
    target_states[$i]="scan"
    draw_target_list
    pause 0.15
    target_states[$i]="dim"
done

# Mark vulnerable target
target_states[1]="vuln"
draw_target_list

add_log "${YELLOW}Vulnerability detected: 192.168.1.101 (MS02-039)${RESET}"
draw_log 23 5
pause 0.5

# Highlight selected target
pos 4 49
printf "${CYAN}┤ ${WHITE}${BOLD}TARGET MATRIX${RESET}${CYAN} ├${RESET}"

add_log "Target selected: SQL01 (MSSQL/1433)"
draw_log 23 5
pause 0.4

# =============================================================================
# SCENE 3: Exploit execution
# =============================================================================
clear

# Minimal header
pos 1 2
printf "${GREEN}SESSION${RESET} ${GRAY}192.168.1.101 via relay chain${RESET}"
pos 1 $((cols - 20))
printf "${GREEN}*${RESET} ${GRAY}NT AUTHORITY\\SYSTEM${RESET}"

draw_panel 2 1 $((lines - 2)) $((cols - 1)) "SQL01 - 192.168.1.101:1433" "$GREEN"

row=4
out() { 
    pos $row 4
    printf '%b' "$1"
    row=$((row + 1))
    pause "$2"
}

out "${GRAY}# Exploit: MS02-039 (SQL Server Resolution Service)${RESET}" 0.2
out "" 0.1
out "${GREEN}\$${RESET} ${WHITE}exploit ms02-039 --target 192.168.1.101${RESET}" 0.3
out "" 0.1
out "${GRAY}[*] Target: 192.168.1.101:1434 (UDP)${RESET}" 0.1
out "${GRAY}[*] Payload: windows/shell_reverse_tcp (376 bytes)${RESET}" 0.1
out "${GRAY}[*] Sending malformed packet...${RESET}" 0.2
out "${GREEN}[+] Buffer overflow triggered${RESET}" 0.1
out "${GREEN}[+] Code execution achieved${RESET}" 0.1
out "${GREEN}[+] Session opened: 192.168.1.101:4444 -> relay chain${RESET}" 0.2
out "" 0.1
out "${GREEN}\$${RESET} ${WHITE}whoami${RESET}" 0.2
out "nt authority\\system" 0.1
out "" 0.1
out "${GREEN}\$${RESET} ${WHITE}hashdump${RESET}" 0.3
out "" 0.1
out "${GRAY}Extracting credentials from SAM...${RESET}" 0.2
out "" 0.1
out "${DIM}USER                  NTLM HASH${RESET}" 0.05
out "${DIM}--------------------------------------------------${RESET}" 0.05
out "${CYAN}Administrator         31d6cfe0d16ae931b73c59d7e0c089c0${RESET}" 0.08
out "${CYAN}sqlservice            e52cac67419a9a224a3b108f3fa6cb6d${RESET}" 0.08
out "${CYAN}backup                8846f7eaee8fb117ad06bdd830b7586c${RESET}" 0.08
out "${CYAN}domain_user           5835048ce94ad0564e29a924a03510ef${RESET}" 0.08
out "" 0.1
out "${GREEN}[+] 4 credentials extracted${RESET}" 0.1
out "${GRAY}[*] Saved: loot/192.168.1.101.txt${RESET}" 0.3

pause 0.8

# =============================================================================
# SCENE 4: Return to TUI with owned target
# =============================================================================
clear

# Redraw TUI
pos 1 2
printf "${BG_GREEN}${WHITE}${BOLD} TERMINALRALLY ${RESET}${BG_BLACK}${GRAY} v0.4.2 ${RESET}"
pos 1 $((cols - 22))
printf "${GRAY}%s${RESET}" "$(date '+%Y-%m-%d %H:%M:%S')"

draw_panel 2 1 $((lines - 2)) $((cols - 1)) "OPERATION NIGHTFALL" "$GREEN"
draw_panel 4 3 16 44 "RELAY CHAIN" "$GREEN"
draw_panel 4 49 16 $((cols - 51)) "TARGET MATRIX" "$GREEN"
draw_panel 21 3 $((lines - 22)) $((cols - 4)) "LIVE FEED" "$GREEN"

# Redraw graph with all active
for node_info in "${node_positions[@]}"; do
    IFS=':' read -r label nx ny <<< "$node_info"
    draw_graph_node "$label" "$nx" "$ny" "active"
done
draw_graph_edges "data"

# Chain status
pos 19 7
printf "${GREEN}Status: ${BRIGHT_GREEN}${BOLD}ACTIVE${RESET}    ${GREEN}Hops: 5/5${RESET}  ${GRAY}Latency: ${WHITE}847ms${RESET}  "

# Updated targets
target_states=("dim" "owned" "dim" "dim")
draw_target_list

# Stats
pos 16 51
printf "${GREEN}Owned: 1${RESET}  ${GRAY}Scanned: 4${RESET}  ${GRAY}Creds: 4${RESET}"

# Final logs
log_buffer=()
add_log "Exploit MS02-039: ${GREEN}SUCCESS${RESET}"
add_log "Privilege: NT AUTHORITY\\SYSTEM"
add_log "Credentials harvested: 4"
add_log "${GREEN}Target 192.168.1.101 OWNED${RESET}"
draw_log 23 5

pause 1.5

# =============================================================================
# FINAL: ASCII Art Title
# =============================================================================
clear

ascii=(
"  _____                   _             _   ____        _ _       "
" |_   _|__ _ __ _ __ ___ (_)_ __   __ _| | |  _ \\ __ _ | | |_   _ "
"   | |/ _ \\ '__| '_ \\ _ \\| | '_ \\ / _\` | | | |_) / _\` || | | | | |"
"   | |  __/ |  | | | | | | | | | | (_| | | |  _ < (_| || | | |_| |"
"   |_|\\___|_|  |_| |_| |_|_|_| |_|\\__,_|_| |_| \\_\\__,_||_|_|\\__, |"
"                                                            |___/ "
)

h=${#ascii[@]}
start_y=$(( (lines - h) / 2 - 2 ))

# Fade in effect
for fade in DIM CYAN GREEN; do
    for i in "${!ascii[@]}"; do
        line="${ascii[$i]}"
        x=$(( (cols - ${#line}) / 2 ))
        pos $((start_y + i)) $x
        eval "printf \"\${$fade}%s\${RESET}\" \"\$line\""
    done
    pause 0.15
done

# Subtitle
pos $((start_y + h + 2)) $(( (cols - 40) / 2 ))
printf "${CYAN}github.com/terminalrally${RESET}"

pause 4
tput cnorm
