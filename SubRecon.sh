#!/bin/bash

NC='\033[0m'
RED='\033[1;38;5;196m'
GREEN='\033[1;38;5;040m'
BLUE='\033[1;38;5;012m'
YELLOW='\033[1;38;5;214m'
CPO='\033[1;38;5;205m'
CP='\033[1;38;5;221m'

function banner(){
    echo -e ${RED}"##################################################################"
    echo -e ${CP}"        ____  _            _      ____  _____           _   _    #"
    echo -e ${CP}"       | __ )| | __ _  ___| | __ |  _ \|___ /  ___ ___ | \ | |   #"
    echo -e ${CP}"       |  _ \| |/ _  |/ __| |/ / | |_) | |_ \ / __/ _ \|  \| |   #"
    echo -e ${CP}"       | |_) | | (_| | (__|   <  |  _ < ___) | (_| (_) | |\  |   #"
    echo -e ${CP}"       |____/|_|\__ _|\___|_|\_\ |_| \_\____/ \___\___/|_| |_|   #"
    echo -e ${CP}"              Subdomain Enumeration Tool                         #"
    echo -e ${BLUE}"              https://github.com/technicalattri                #"
    echo -e ${YELLOW}"              Coded By: Nitin Attri                           #"
    echo -e ${RED}"################################################################## \n "
}

function subdomain_enumeration(){
    clear
    banner
    echo -n -e ${BLUE}"\n[+] Enter Domain (e.g example.com): "
    read domain
    mkdir -p $domain $domain/domain_enum $domain/final_domains $domain/takeovers

    echo -e ${RED}"\n[+] Subdomain Enumeration Started: "
    sleep 1

    echo -e ${CPO}"\n[+] Crt.sh Enumeration Started:- "
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee $domain/domain_enum/crt.txt

    echo -e ${CP}"\n[+] Subfinder Enumeration Started:- "
    subfinder -d $domain -o $domain/domain_enum/subfinder.txt

    echo -e ${GREEN}"\n[+] Assetfinder Enumeration Started:- "
    assetfinder -subs-only $domain | tee $domain/domain_enum/assetfinder.txt

    echo -e ${BLUE}"\n[+] Amass Enumeration Started:- "
    amass enum -passive -d $domain -o $domain/domain_enum/amass.txt

    echo -e ${YELLOW}"\n[+] Shuffledns Enumeration Started:- "
    shuffledns -d $domain -w /usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -r ~/tools/resolvers/resolver.txt -o $domain/domain_enum/shuffledns.txt

    echo -e ${CP}"\n[+] Collecting All Subdomains Into Single File:- "
    cat $domain/domain_enum/*.txt > $domain/domain_enum/all.txt

   echo -e ${BLUE}"\n[+] Resolving All Subdomains:- "
0    shuffledns -d $domain -list $domain/domain_enum/all.txt -o $domain/final_domains/domains.txt -r ~/tools/resolvers/resolver.txt

    echo -e ${GREEN}"\n[+] Checking Services On Subdomains:- "
    cat $domain/final_domains/domains.txt | httpx -threads 30 -o $domain/final_domains/httpx.txt

    echo -e ${RED}"\n[+] Searching For Subdomain TakeOver:- "
    subzy -hide_fails -targets $domain/domain_enum/all.txt | tee $domain/takeovers/subzy.txt
    subjack -w $domain/domain_enum/all.txt -t 100 -timeout 30 -o $domain/takeovers/take.txt -ssl

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
            mkdir -p $domain $domain/domain_enum $domain/final_domains $domain/takeovers

            echo -e ${RED}"\n[+] Subdomain Enumeration Started for $domain: "
            sleep 1

            echo -e ${CPO}"\n[+] Crt.sh Enumeration Started:- "
            curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee $domain/domain_enum/crt.txt

            echo -e ${CP}"\n[+] Subfinder Enumeration Started:- "
            subfinder -d $domain -o $domain/domain_enum/subfinder.txt

            echo -e ${GREEN}"\n[+] Assetfinder Enumeration Started:- "
            assetfinder -subs-only $domain | tee $domain/domain_enum/assetfinder.txt

            echo -e ${BLUE}"\n[+] Amass Enumeration Started:- "
            amass enum -passive -d $domain -o $domain/domain_enum/amass.txt

            echo -e ${YELLOW}"\n[+] Shuffledns Enumeration Started:- "
            shuffledns -d $domain -w /usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -r ~/tools/resolvers/resolver.txt -o $domain/domain_enum/shuffledns.txt

            echo -e ${CP}"\n[+] Collecting All Subdomains Into Single File:- "
            cat $domain/domain_enum/*.txt > $domain/domain_enum/all.txt

            echo -e ${BLUE}"\n[+] Resolving All Subdomains:- "
            shuffledns -d $domain -list $domain/domain_enum/all.txt -o $domain/final_domains/domains.txt -r ~/tools/resolvers/resolver.txt

            echo -e ${GREEN}"\n[+] Checking Services On Subdomains:- "
            cat $domain/final_domains/domains.txt | httpx -threads 30 -o $domain/final_domains/httpx.txt

            echo -e ${RED}"\n[+] Searching For Subdomain TakeOver:- "
            subzy -hide_fails -targets $domain/domain_enum/all.txt | tee $domain/takeovers/subzy.txt
            subjack -w $domain/domain_enum/all.txt -t 100 -timeout 30 -o $domain/takeovers/take.txt -ssl

            echo -e ${GREEN}"\n[+] Finished Subdomain Enumeration for $domain"
        fi
    done < "$file_path"
}

function menu(){
    clear
    banner
    echo -e -n ${YELLOW}"\n[*] Choose an option\n"
    echo -e "  ${NC}[${GREEN}"1"${NC}]${BLUE} Single Domain Enumeration"
    echo -e "  ${NC}[${GREEN}"2"${NC}]${BLUE} Bulk Domain Enumeration from File"
    echo -e "  ${NC}[${GREEN}"3"${NC}]${BLUE} Exit"
    echo -n -e ${RED}"\n[+] Select: "
    read choice

    if [ $choice -eq 1 ]; then
        subdomain_enumeration
    elif [ $choice -eq 2 ]; then
        bulk_subdomain_enumeration
    elif [ $choice -eq 3 ]; then
        exit
    else
        echo -e ${RED}"Invalid choice, exiting."
        exit 1
    fi
}

menu
