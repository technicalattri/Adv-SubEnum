# Adv-SubEnum

**Adv-SubEnum** is a powerful and advanced subdomain enumeration tool designed to simplify and automate the process of discovering subdomains. It combines multiple tools to ensure comprehensive coverage, making it ideal for security researchers, penetration testers, and bug bounty hunters.

## Features

- **Automated Dependency Installation**: Automatically installs all required tools and dependencies, including Go, `jq`, `curl`, and others.
- **Integration with Popular Tools**: Leverages industry-standard tools such as Subfinder, Assetfinder, Amass, Shuffledns, and Httpx for effective subdomain enumeration.
- **User-Friendly Interface**: Easy-to-use with a clear and colorful output to highlight important information.
- **Customizable**: The script can be easily modified to include additional tools or customize the behavior to fit specific needs.

## Prerequisites

Before using **Adv-SubEnum**, ensure that your system meets the following requirements:

- **Operating System**: Linux (preferred), macOS
- **Go**: Required for installing certain tools; the script will automatically install it if not present.
- **Internet Connection**: Required to download dependencies and tools.

## Installation

Clone the repository and navigate to the directory:

```bash
git clone https://github.com/technicalattri/Adv-SubEnum.git
cd Adv-SubEnum
```

### Installing Dependencies

To install all the necessary dependencies, run the `install.sh` script:

```bash
chmod +x install.sh
./install.sh
```

This script will:

1. Check if Go is installed. If not, it will prompt you to install it.
2. Install the required tools like `jq`, `curl`, `Subfinder`, `Assetfinder`, `Amass`, `Shuffledns`, and `Httpx`.

## Usage

After installing the dependencies, you can run the **Adv-SubEnum** tool:

```bash
chmod +x SubRecon.sh
./SubRecon.sh
```

### Example

```bash
./SubRecon.sh example.com
```

This command will run the subdomain enumeration process for `example.com` using the integrated tools and display the results in the terminal.

## Tools Included

- **Subfinder**: Fast passive subdomain enumeration tool.
- **Assetfinder**: Find related domains and subdomains using multiple sources.
- **Amass**: In-depth subdomain enumeration with reconnaissance capabilities.
- **Shuffledns**: Subdomain enumeration tool that uses massdns and various wordlists.
- **Httpx**: HTTP toolkit for probing and testing web servers.

## Contributing

Contributions are welcome! If you have suggestions, find bugs, or want to add features, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- **Nitin Attri** - [GitHub](https://github.com/technicalattri)
- **Komal0x01** - [GitHub](https://github.com/Komal0x01)

## Acknowledgments

- Inspired by the amazing tools created by the open-source community.
- Special thanks to ProjectDiscovery, Tomnomnom, and OWASP for their incredible contributions to the security community.

