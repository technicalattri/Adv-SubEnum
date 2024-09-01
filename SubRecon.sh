#!/bin/bash

NC='\033[0m'
RED='\033[1;38;5;196m'
GREEN='\033[1;38;5;040m'
BLUE='\033[1;38;5;012m'
YELLOW='\033[1;38;5;214m'
CPO='\033[1;38;5;205m'
CP='\033[1;38;5;221m'

output_dir=""

function banner(){
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

function set_output_directory(){
    echo -n -e ${BLUE}"\n[+] Enter output directory (default is current directory): "
    read output_dir
    if [[ -z "$output_dir" ]]; then
        output_dir="."
    fi
    mkdir -p "$output_dir"
    echo -e ${GREEN}"\n[+] Output will be stored in: $output_dir"
}

function sort_and_deduplicate_subdomains(){
    echo -e ${YELLOW}"\n[+] Sorting and removing duplicates from all gathered subdomains"
    sort -u $output_dir/all_subdomains.txt -o $output_dir/all_subdomains_sorted.txt
    echo -e ${GREEN}"\n[+] Deduplicated and sorted subdomains saved to: $output_dir/all_subdomains_sorted.txt"
}

function subdomain_enumeration(){
    clear
    banner
    echo -n -e ${BLUE}"\n[+] Enter Domain (e.g example.com): "
    read domain
    mkdir -p $output_dir/$domain $output_dir/$domain/domain_enum $output_dir/$domain/final_domains $output_dir/$domain/takeovers

    echo -e ${RED}"\n[+] Subdomain Enumeration Started: "
    sleep 1

    echo -e ${CPO}"\n[+] Crt.sh Enumeration Started:- "
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee $output_dir/$domain/domain_enum/crt.txt

    echo -e ${CP}"\n[+] Subfinder Enumeration Started:- "
    subfinder -d $domain -o $output_dir/$domain/domain_enum/subfinder.txt

    echo -e ${GREEN}"\n[+] Assetfinder Enumeration Started:- "
    assetfinder -subs-only $domain | tee $output_dir/$domain/domain_enum/assetfinder.txt

    echo -e ${BLUE}"\n[+] Amass Enumeration Started:- "
    amass enum -passive -d $domain -o $output_dir/$domain/domain_enum/amass.txt

    echo -e ${YELLOW}"\n[+] Shuffledns Enumeration Started:- "
    shuffledns -d $domain -w /usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -r ~/tools/resolvers/resolver.txt -o $output_dir/$domain/domain_enum/shuffledns.txt

    echo -e ${CP}"\n[+] Collecting All Subdomains Into Single File:- "
    cat $output_dir/$domain/domain_enum/*.txt | sort -u | tee -a $output_dir/all_subdomains.txt

    echo -e ${BLUE}"\n[+] Resolving All Subdomains:- "
    shuffledns -d $domain -list $output_dir/$domain/domain_enum/all.txt -o $output_dir/$domain/final_domains/domains.txt -r ~/tools/resolvers/resolver.txt

    echo -e ${GREEN}"\n[+] Checking Services On Subdomains:- "
    cat $output_dir/$domain/final_domains/domains.txt | httpx -threads 30 -o $output_dir/$domain/final_domains/httpx.txt

    echo -e ${RED}"\n[+] Searching For Subdomain TakeOver:- "
    subzy -hide_fails -targets $output_dir/$domain/domain_enum/all.txt | tee $output_dir/$domain/takeovers/subzy.txt
    subjack -w $output_dir/$domain/domain_enum/all.txt -t 100 -timeout 30 -o $output_dir/$domain/takeovers/take.txt -ssl

    echo -e ${GREEN}"\n[+] Finished Subdomain Enumeration"
}

function bulk_subdomain_enumeration(){
    clear
    banner
    echo -n -e ${BLUE}"\n[+] Enter File Path with List of Domains: "
    read file_path

    if [[ ! -f $file_path ]]; then
        echo -e ${RED}"File not found!"
        exit 1
    fi

    while IFS= read -r domain; do
        if [[ -n $domain ]]; then
            echo -e ${BLUE}"\n[+] Processing Domain: $domain"
            mkdir -p $output_dir/$domain $output_dir/$domain/domain_enum $output_dir/$domain/final_domains $output_dir/$domain/takeovers

            echo -e ${RED}"\n[+] Subdomain Enumeration Started for $domain: "
            sleep 1

            echo -e ${CPO}"\n[+] Crt.sh Enumeration Started:- "
            curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee $output_dir/$domain/domain_enum/crt.txt

            echo -e ${CP}"\n[+] Subfinder Enumeration Started:- "
            subfinder -d $domain -o $output_dir/$domain/domain_enum/subfinder.txt

            echo -e ${GREEN}"\n[+] Assetfinder Enumeration Started:- "
            assetfinder -subs-only $domain | tee $output_dir/$domain/domain_enum/assetfinder.txt

            echo -e ${BLUE}"\n[+] Amass Enumeration Started:- "
            amass enum -passive -d $domain -o $output_dir/$domain/domain_enum/amass.txt

            echo -e ${YELLOW}"\n[+] Shuffledns Enumeration Started:- "
            shuffledns -d $domain -w /usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -r ~/tools/resolvers/resolver.txt -o $output_dir/$domain/domain_enum/shuffledns.txt

            echo -e ${CP}"\n[+] Collecting All Subdomains Into Single File:- "
            cat $output_dir/$domain/domain_enum/*.txt | sort -u | tee -a $output_dir/all_subdomains.txt

            echo -e ${BLUE}"\n[+] Resolving All Subdomains:- "
            shuffledns -d $domain -list $output_dir/$domain/domain_enum/all.txt -o $output_dir/$domain/final_domains/domains.txt -r ~/tools/resolvers/resolver.txt

            echo -e ${GREEN}"\n[+] Checking Services On Subdomains:- "
            cat $output_dir/$domain/final_domains/domains.txt | httpx -threads 30 -o $output_dir/$domain/final_domains/httpx.txt

            echo -e ${RED}"\n[+] Searching For Subdomain TakeOver:- "
            subzy -hide_fails -targets $output_dir/$domain/domain_enum/all.txt | tee $output_dir/$domain/takeovers/subzy.txt
            subjack -w $output_dir/$domain/domain_enum/all.txt -t 100 -timeout 30 -o $output_dir/$domain/takeovers/take.txt -ssl

            echo -e ${GREEN}"\n[+] Finished Subdomain Enumeration for $domain"
        fi
    done < "$file_path"
}

function menu(){
    clear
    banner
    set_output_directory
    echo -e -n ${YELLOW}"\n[*] Choose an option\n"
    echo -e "  ${NC}[${GREEN}"1"${NC}]${BLUE} Single Domain Enumeration"
    echo -e "  ${NC}[${GREEN}"2"${NC}]${BLUE} Bulk Domain Enumeration from File"
    echo -e "  ${NC}[${GREEN}"3"${NC}]${BLUE} Exit"
    echo -n -e ${RED}"\n[+] Select: "
    read choice

    if [ $choice -eq 1 ]; then
        subdomain_enumeration
        sort_and_deduplicate_subdomains
    elif [ $choice -eq 2]; then
        bulk_subdomain_enumeration
        sort_and_deduplicate_subdomains
    elif [ $choice -eq 3 ]; then
        exit
    else
        echo -e ${RED}"Invalid choice, exiting."
        exit 1
    fi
}

menu
