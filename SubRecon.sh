#!/bin/bash


NC='\033[0m'
RED='\033[1;38;5;196m'
GREEN='\033[1;38;5;040m'
BLUE='\033[1;38;5;012m'
YELLOW='\033[1;38;5;214m'
CPO='\033[1;38;5;205m'
CP='\033[1;38;5;221m'

output_dir="."
domain=""
resolver_file="$HOME/tools/resolvers/resolvers.txt"  # Default resolver path
wordlist_dir="$HOME/tools/wordlists"
threads=100

# ==============================================
# BANNER
# ==============================================
function banner() {
    clear
    echo -e ${RED}"##################################################################"
    echo -e ${CP}"         ____        _     ____                                   #"
    echo -e ${CP}"        / ___| _   _| |__ |  _ \ ___  ___ ___  _ __               #"
    echo -e ${CP}"        \___ \| | | | '_ \| |_) / _ \/ __/ _ \| '_ \              #"
    echo -e ${CP}"         ___) | |_| | |_) |  _ <  __/ (_| (_) | | | |             #"
    echo -e ${CP}"        |____/ \__,_|_.__/|_| \_\___|\___\___/|_| |_|             #"
    echo -e ${CP}"              Subdomain Enumeration Tool                          #"
    echo -e ${BLUE}"              https://github.com/technicalattri                 #"
    echo -e ${YELLOW}"              Coded By: Nitin Attri && Komal0x01              #"
    echo -e ${RED}"################################################################## \n "
}

# ==============================================
# CHECK & INSTALL MISSING TOOLS
# ==============================================
function check_tools() {
    echo -e "${YELLOW}[+] Checking required tools...${NC}"
    declare -A tools=(
        ["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        ["assetfinder"]="go install -v github.com/tomnomnom/assetfinder@latest"
        ["amass"]="go install -v github.com/owasp-amass/amass/v3/...@master"
        ["shuffledns"]="go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
        ["httpx"]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
        ["dnsx"]="go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        ["subzy"]="go install -v github.com/LukaSikic/subzy@latest"
        ["subjack"]="go install -v github.com/haccer/subjack@latest"
        ["jq"]="sudo apt install jq -y"
        ["anew"]="go install -v github.com/tomnomnom/anew@latest"
        ["gotator"]="go install -v github.com/Josue87/gotator@latest"
    )

    for tool in "${!tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}[-] $tool not found! Installing...${NC}"
            if ! eval "${tools[$tool]}" 2>&1 | tee -a setup_errors.log; then
                echo -e "${RED}[!] Failed to install $tool! Please install manually.${NC}"
                echo -e "${YELLOW}Try: ${tools[$tool]}${NC}"
                read -p "Press enter to continue or Ctrl+C to exit..."
            fi
        else
            echo -e "${GREEN}[+] $tool installed.${NC}"
        fi
    done

    # Check and create wordlists directory
    if [[ ! -d "$wordlist_dir" ]]; then
        mkdir -p "$wordlist_dir"
        echo -e "${YELLOW}[+] Created wordlists directory: $wordlist_dir${NC}"
    fi

    # Check resolvers file
    if [[ ! -f "$resolver_file" ]]; then
        echo -e "${RED}[-] Resolvers file not found! Fetching fresh resolvers...${NC}"
        mkdir -p "$(dirname "$resolver_file")"
        if ! curl -s "https://raw.githubusercontent.com/projectdiscovery/dnsx/main/wordlists/resolvers.txt" -o "$resolver_file"; then
            echo -e "${RED}[!] Failed to download resolvers!${NC}"
            echo -e "${YELLOW}Please manually create $resolver_file with DNS resolvers${NC}"
            read -p "Press enter to continue with default resolvers or Ctrl+C to exit..."
        fi
    fi

    # Check for common wordlists
    if [[ ! -f "$wordlist_dir/all.txt" ]]; then
        echo -e "${YELLOW}[+] Downloading common wordlists...${NC}"
        if ! curl -s "https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt" -o "$wordlist_dir/all.txt"; then
            echo -e "${RED}[!] Failed to download wordlist!${NC}"
            echo -e "${YELLOW}Please manually download wordlists to $wordlist_dir${NC}"
            read -p "Press enter to continue with limited wordlists or Ctrl+C to exit..."
        fi
    fi
}

# ==============================================
# SUBDOMAIN ENUMERATION
# ==============================================
function subdomain_enumeration() {
    echo -e -n "${BLUE}[+] Enter Domain (e.g., example.com): ${NC}"
    read -r domain

    # Validate domain input
    if [[ -z "$domain" ]]; then
        echo -e "${RED}[!] Domain cannot be empty!${NC}"
        return 1
    fi

    # Create temp directory
    temp_dir="$(mktemp -d -t subs.XXXXXXXXXX)"
    echo -e "${YELLOW}[+] Using temp directory: $temp_dir${NC}"

    echo -e "${RED}\n[+] Starting FULL Subdomain Enumeration on: $domain${NC}"
    echo -e "${YELLOW}[+] All final results will be saved in current directory as:"
    echo -e "    - ${domain}_subdomains.txt"
    echo -e "    - ${domain}_ips.txt${NC}"
    sleep 2

    # ==============================================
    # PASSIVE ENUMERATION
    # ==============================================
    echo -e "${CPO}\n[+] Passive Enumeration (Max Sources)${NC}"

    # 1. Crt.sh (Certificate Transparency)
    echo -e "${CP}  [*] Running Crt.sh...${NC}"
    if ! curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' 2>"${temp_dir}/crt.err" | sed 's/\*\.//g' | sort -u > "${temp_dir}/crt.txt"; then
        echo -e "${RED}  [!] Crt.sh failed: $(cat "${temp_dir}/crt.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/crt.txt") subdomains from Crt.sh${NC}"
    fi

    # 2. Subfinder (Fast Passive)
    echo -e "${CP}  [*] Running Subfinder...${NC}"
    if ! subfinder -d "$domain" -o "${temp_dir}/subfinder.txt" 2>"${temp_dir}/subfinder.err"; then
        echo -e "${RED}  [!] Subfinder failed: $(cat "${temp_dir}/subfinder.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/subfinder.txt") subdomains from Subfinder${NC}"
    fi

    # 3. Assetfinder (Fast Passive)
    echo -e "${CP}  [*] Running Assetfinder...${NC}"
    if ! assetfinder -subs-only "$domain" 2>"${temp_dir}/assetfinder.err" > "${temp_dir}/assetfinder.txt"; then
        echo -e "${RED}  [!] Assetfinder failed: $(cat "${temp_dir}/assetfinder.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/assetfinder.txt") subdomains from Assetfinder${NC}"
    fi

    # 4. Amass (Passive Only) - WITH TIMEOUT TO PREVENT HANGING
    echo -e "${CP}  [*] Running Amass (Passive)...${NC}"
    timeout 300 amass enum -passive -d "$domain" -o "${temp_dir}/amass.txt" 2>"${temp_dir}/amass.err"
    if [[ $? -eq 124 ]]; then
        echo -e "${YELLOW}  [!] Amass timed out after 5 minutes (common issue), using partial results${NC}"
    elif [[ $? -ne 0 ]]; then
        echo -e "${RED}  [!] Amass failed: $(cat "${temp_dir}/amass.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/amass.txt") subdomains from Amass${NC}"
    fi
    # 5. Wayback Machine (Historical Data)
    echo -e "${CP}  [*] Checking Wayback Machine...${NC}"
    if ! curl -s "http://web.archive.org/cdx/search/cdx?url=*.$domain/*&output=text&fl=original&collapse=urlkey" 2>"${temp_dir}/wayback.err" | sed -e 's_https*://__' -e "s/\/.*//" | sort -u > "${temp_dir}/wayback.txt"; then
        echo -e "${RED}  [!] Wayback failed: $(cat "${temp_dir}/wayback.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/wayback.txt") subdomains from Wayback${NC}"
    fi

    # 6. BufferOverrun (Rapid7 FDNS)
    echo -e "${CP}  [*] Checking BufferOverrun...${NC}"
    if ! curl -s "https://dns.bufferover.run/dns?q=.$domain" 2>"${temp_dir}/bufferover.err" | jq -r '.FDNS_A[]' 2>>"${temp_dir}/bufferover.err" | cut -d',' -f2 | sort -u > "${temp_dir}/bufferover.txt"; then
        echo -e "${RED}  [!] BufferOverrun failed: $(cat "${temp_dir}/bufferover.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/bufferover.txt") subdomains from BufferOverrun${NC}"
    fi

    # ==============================================
    # ACTIVE ENUMERATION (DEEP SCAN)
    # ==============================================
    echo -e "${YELLOW}\n[+] Active Enumeration (Brute Forcing)${NC}"

    # 1. Generate permutations
    echo -e "${YELLOW}  [*] Generating Permutations...${NC}"
    if ! gotator -sub "$wordlist_dir/all.txt" -perm "$wordlist_dir/permutations.txt" -depth 1 -numbers 10 -mindup -adv -md 2>"${temp_dir}/gotator.err" > "${temp_dir}/permutations.txt"; then
        echo -e "${RED}  [!] Gotator failed: $(cat "${temp_dir}/gotator.err")${NC}"
    else
        echo -e "${GREEN}  [+] Generated $(wc -l < "${temp_dir}/permutations.txt") permutations${NC}"
    fi

    # 2. Shuffledns (MassDNS + Large Wordlist)
    echo -e "${YELLOW}  [*] Running Shuffledns (Brute-Force)...${NC}"
    if ! shuffledns -d "$domain" -w "$wordlist_dir/all.txt" -r "$resolver_file" -o "${temp_dir}/shuffledns.txt" -t $threads 2>"${temp_dir}/shuffledns.err"; then
        echo -e "${RED}  [!] Shuffledns failed: $(cat "${temp_dir}/shuffledns.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/shuffledns.txt") subdomains from Shuffledns${NC}"
    fi

    # 3. Pure DNS (Fast Brute-Force)
    echo -e "${YELLOW}  [*] Running PureDNS (Permutations)...${NC}"
    if ! puredns bruteforce "${temp_dir}/permutations.txt" "$domain" -r "$resolver_file" -q -t $threads 2>"${temp_dir}/puredns.err" | tee "${temp_dir}/puredns.txt"; then
        echo -e "${RED}  [!] Puredns failed: $(cat "${temp_dir}/puredns.err")${NC}"
    else
        echo -e "${GREEN}  [+] Found $(wc -l < "${temp_dir}/puredns.txt") subdomains from Puredns${NC}"
    fi

    # ==============================================
    # COMBINE & RESOLVE SUBDOMAINS
    # ==============================================
    echo -e "${GREEN}\n[+] Merging & Deduplicating Subdomains${NC}"
    cat "${temp_dir}/"*.txt 2>/dev/null | sort -u | anew -q "${temp_dir}/all_subdomains.txt" 2>"${temp_dir}/merge.err"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[!] Merging failed: $(cat "${temp_dir}/merge.err")${NC}"
    else
        echo -e "${GREEN}[+] Found $(wc -l < "${temp_dir}/all_subdomains.txt") total unique subdomains${NC}"
    fi

    echo -e "${GREEN}[+] Resolving Subdomains (Removing Dead Ones)...${NC}"
    if ! shuffledns -d "$domain" -list "${temp_dir}/all_subdomains.txt" -r "$resolver_file" -o "${temp_dir}/resolved_domains.txt" -t $threads 2>"${temp_dir}/resolve.err"; then
        echo -e "${RED}[!] DNS resolution failed: $(cat "${temp_dir}/resolve.err")${NC}"
    else
        echo -e "${GREEN}[+] $(wc -l < "${temp_dir}/resolved_domains.txt") subdomains resolved successfully${NC}"
    fi

    # ==============================================
    # RESOLVE TO IP ADDRESSES
    # ==============================================
    echo -e "${BLUE}\n[+] Resolving IP Addresses...${NC}"
    if ! dnsx -l "${temp_dir}/resolved_domains.txt" -a -resp-only -silent -r "$resolver_file" -t $threads 2>"${temp_dir}/dnsx.err" | sort -u > "${temp_dir}/ips.txt"; then
        echo -e "${RED}[!] IP resolution failed: $(cat "${temp_dir}/dnsx.err")${NC}"
    else
        echo -e "${GREEN}[+] Found $(wc -l < "${temp_dir}/ips.txt") unique IP addresses${NC}"
    fi

    # ==============================================
    # CHECK LIVE SUBDOMAINS (HTTPX)
    # ==============================================
    echo -e "${BLUE}\n[+] Checking Live Subdomains (HTTPX)...${NC}"
    if ! httpx -l "${temp_dir}/resolved_domains.txt" -o "${temp_dir}/live.txt" -t $threads 2>"${temp_dir}/httpx.err"; then
        echo -e "${RED}[!] HTTPX failed: $(cat "${temp_dir}/httpx.err")${NC}"
    else
        echo -e "${GREEN}[+] Found $(wc -l < "${temp_dir}/live.txt") live subdomains${NC}"
    fi

    # ==============================================
    # SAVE FINAL RESULTS TO CURRENT DIRECTORY
    # ==============================================
    echo -e "${GREEN}\n[+] Saving final results to current directory...${NC}"
    
    # Save subdomains
    if [[ -f "${temp_dir}/resolved_domains.txt" ]]; then
        sort -u "${temp_dir}/resolved_domains.txt" > "./${domain}_subdomains.txt"
        echo -e "${GREEN}[+] Subdomains saved to: ./${domain}_subdomains.txt ($(wc -l < "./${domain}_subdomains.txt") entries)${NC}"
    else
        echo -e "${RED}[!] Failed to save subdomains - no resolved domains found${NC}"
    fi
    
    # Save IPs
    if [[ -f "${temp_dir}/ips.txt" ]]; then
        sort -u "${temp_dir}/ips.txt" > "./${domain}_ips.txt"
        echo -e "${GREEN}[+] IPs saved to: ./${domain}_ips.txt ($(wc -l < "./${domain}_ips.txt") entries)${NC}"
    else
        echo -e "${RED}[!] Failed to save IPs - no IPs found${NC}"
    fi

    # ==============================================
    # CLEANUP
    # ==============================================
    echo -e "${YELLOW}\n[+] Cleaning up temporary files...${NC}"
    rm -rf "$temp_dir"
}

# ==============================================
# BULK DOMAIN ENUMERATION (FROM FILE)
# ==============================================
function bulk_subdomain_enumeration() {
    echo -e -n "${BLUE}[+] Enter File Path with Domains (one per line): ${NC}"
    read -r file_path

    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}[-] File not found!${NC}"
        return 1
    fi

    while IFS= read -r domain || [[ -n "$domain" ]]; do
        if [[ -n "$domain" ]]; then
            echo -e "\n${RED}[+] Processing Domain: $domain${NC}"
            subdomain_enumeration
        fi
    done < "$file_path"
}

# ==============================================
# MAIN MENU
# ==============================================
function menu() {
    banner
    check_tools

    while true; do
        echo -e -n "${YELLOW}\n[+] Choose an option:\n"
        echo -e "  ${NC}[${GREEN}1${NC}]${BLUE} Single Domain Enumeration"
        echo -e "  ${NC}[${GREEN}2${NC}]${BLUE} Bulk Domain Enumeration (From File)"
        echo -e "  ${NC}[${GREEN}3${NC}]${BLUE} Exit"
        echo -e -n "${RED}\n[+] Select: ${NC}"
        read -r choice

        case "$choice" in
            1) subdomain_enumeration ;;
            2) bulk_subdomain_enumeration ;;
            3) exit 0 ;;
            *) echo -e "${RED}[-] Invalid choice!${NC}" ;;
        esac
    done
}

# ==============================================
# ERROR HANDLING & EXECUTION
# ==============================================
trap 'echo -e "${RED}\n[!] Script interrupted. Exiting...${NC}"; rm -rf "$temp_dir"; exit 1' INT

# Run the tool
menu
