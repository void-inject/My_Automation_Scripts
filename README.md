# Automation Scripts & Utilities

This repository contains a collection of Bash scripts designed to automate repetitive tasks, streamline workflows, and simplify daily operations.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Setup](#setup)
- [Scripts](#scripts)
    - [Log-Recorder.sh](#log-recordersh)
    - [IP-Scoper.sh](#ip-scopersh)
    - [git-pusher.sh](#git-pushersh)
    - [WatchDog.sh](#watchdogssh)
    - [Banner-Grabber.sh](#banner-grabbersh)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository offers several automation scripts for use in various environments, particularly Linux systems. The scripts are written in **Bash** and cover tasks such as Git management, system maintenance, and network operations.

## Requirements

Before using the scripts, make sure the following dependencies are installed:

- **Bash**
- `git` (required for `git-pusher.sh`)
- `arp-scan` (required for `Telegram-alerts.sh`)
- `nmap` (required for `IP-scoper.sh`)
- `netcat` (required for `Banner-Grabber.sh`)

## Setup

1. Clone the repository:

```bash
git clone https://github.com/void-inject/My_Automation_Scripts.git Automation_Scripts
cd Automation_Scripts
```

2. Make the scripts executable:

```bash
chmod +x *.sh
```

## Scripts

### Log-Recorder.sh

#### Description:

This script creates a logging mechanism for terminal sessions, making it easier to track and review terminal activity.

#### Usage:

```bash
./Log-Recorder.sh
```

---

### IP-Scoper.sh

#### Description:

This script has three main use cases:

1. Generate a list of IP addresses for a given subnet and save them in an output file. The output file is named based on the subnet (e.g., `192.168.1.txt`).
2. Check the availability of IP addresses listed in a text file, removing unreachable IPs.
3. Perform a scan of hosts using `nmap` to find open TCP ports and save the results to files named `port-<port>.txt`.
4. Optionally, combine all three functions.

#### Example Usage:

```bash
./IP-Scoper.sh -g 192.168.1 -s 192-168-1-host.txt -f 192-168-1-host.txt
```

---

### git-pusher.sh

#### Description:

This script automates the process of checking multiple Git repositories for uncommitted changes and keeps them up to date with the remote repository.

#### Usage:

```bash
./git-pusher.sh
```

---

### WatchDog.sh

#### Description:

This script offers two key functionalities:

1. Continuously perform ARP scans on a target network using `arp-scan`, detecting new hosts and logging them in a separate file. It sends notifications to Telegram with host details when new hosts are detected. The script randomizes scan intervals to reduce network load.
2. Continuously check if a specified port is open on a host. Once the port is found open, it uses `nmap` to perform service discovery and logs the results.

#### Example Usage:

```bash
./Telegram-alerts.sh -hp 192.168.1.0/24 80 192-168-1-hosts.txt eth0
```

---

### Banner-Grabber.sh

#### Description:

This script uses `netcat` and `curl` to grab banners from a specified port on multiple hosts, either from a file or a single IP.

#### Example Usage:

```bash
./Banner-Grabber.sh 
```

---

## Contributing

Contributions are welcome! To contribute, fork the repository, make your changes, and submit a pull request. Please adhere to the project's code quality and documentation guidelines.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.