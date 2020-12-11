# py-package-manager
A collection of scripts that make it easier to manage my python packages

## Installation
```bash
# Currently this requires cloning the repo into a specific location
git -C ~/extras clone https://github.com/barretobrock/py-package-manager.git
```

## Usage
### Initializing with a new repo
We'll be running the script that essentially copies all the necessary management scripts into the desired repo:
 - cd into the target repo
 ```bash
 cd ~/extras/my_repo
 ```
 - run the installation script
 ```bash
 sh ~/path/to/py-package-manager/install.sh
 ```