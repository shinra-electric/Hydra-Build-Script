#!/usr/bin/env zsh

# ANSI color codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# This gets the location that the script is being run from and moves there.
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

# Detect CPU architecture
ARCH="$(uname -m)"

introduction() {
	echo "\n${PURPLE}This script is for compiling ${GREEN}Hydra${PURPLE} for ${GREEN}Apple Silicon${NC}\n"
	
	if [[ $ARCH == "x86_64" ]]; then 
		echo "\n${PURPLE}Your CPU architecture is ${RED}$ARCH${NC}\n"
		echo "${RED}This script can't be run on an Intel Mac${NC}\n"
		exit 0
	fi
	
	echo "${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required${NC}"
	echo "${PURPLE}If they are not present you will be prompted to install them${NC}\n"
}

homebrew_check() {
	if ! command -v brew &> /dev/null; then
		echo "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ "${ARCH_NAME}" == "arm64" ]]; then 
			(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/opt/homebrew/bin/brew shellenv)"
			else 
			(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/usr/local/bin/brew shellenv)"
		fi
		
		# Check for errors
		if [ $? -ne 0 ]; then
			echo "${RED}There was an issue installing Homebrew${NC}"
			echo "${PURPLE}Quitting script...${NC}"	
			exit 1
		fi
	else
		echo  "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
		brew update
	fi
}

# Function for checking for an individual dependency
single_dependency_check() {
	if [ -d "$(brew --prefix)/opt/$1" ]; then
		echo "${GREEN}Found $1. Checking for updates...${NC}"
			brew upgrade $1
	else
		 echo "${PURPLE}Did not find $1. Installing...${NC}"
		brew install $1
	fi
}

dependencies_check() {
	echo "${PURPLE}Checking for native Homebrew dependencies...${NC}"
	# Required native Homebrew packages
	deps=( boost cmake ninja sdl3 fmt )
	
	for dep in $deps[@]
	do 
		single_dependency_check $dep
	done
}

# Update individual submodule
git_update_submodules() {
	echo "${PURPLE}Updating submodules...${NC}"
	git submodule update --init --recursive
}

clone_repo() { 
# Check to see if the source folder exists
	if [ ! -d "hydra" ]; then
		echo "${PURPLE}Cloning Hydra Repository...${NC}"
		git clone https://github.com/SamoZ256/hydra
		cd hydra
		git_update_submodules
		
	else
		echo "${PURPLE}Hydra repository already exists${NC}"
		cd hydra
		rm -rf build
		git pull origin main
		git_update_submodules
	fi
}

build() {
	# Set variables
	release_type_menu
	frontend_menu

	# Configure build system
	echo "${PURPLE}Configuring build...${NC}"
	cmake . -B build \
	-DCMAKE_BUILD_TYPE=$BUILD_MODE \
	-DFRONTEND=$FRONTEND_MODE \
	-DMACOS_BUNDLE=ON \
	-GNinja
	
	# Check for errors
	if [ $? -ne 0 ]; then
		echo "${RED}There was an issue configuring CMake${NC}"
		echo "${PURPLE}Quitting script...${NC}"	
		exit 1
	fi
	
	# Build
	echo "${PURPLE}Building...${NC}"
	ninja -C build
	
	# Check whether the build was successful
	if [ $? -ne 0 ]; then
		echo "\n${RED}Building failed${NC}\n"
		exit 1
	fi 
	
	# Bundle dependencies
	echo "${PURPLE}Bundling dependencies...${NC}"
	dylibbundler -of -cd -b -x  build/bin/Hydra.app/Contents/MacOS/Hydra -d build/bin/Hydra.app/Contents/libs
	
	# Codesign
	# echo "${PURPLE}Codesigning...${NC}"
	# codesign --force --deep --sign - build/bin/Hydra.app/Contents/MacOS/Hydra
	
}

main_menu() {
	PS3='What would you like to do? '
	OPTIONS=(
		"Build"
		"Build with Homebrew checks"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Build")
				echo "\n${RED}Skipping Homebrew checks${NC}"
				echo "${PURPLE}The script will fail if any of the dependencies are missing${NC}\n"
				clone_repo
				continue_menu
				build
				cleanup_menu
				break
				;;
			"Build with Homebrew checks")
				homebrew_check
				dependencies_check
				clone_repo
				continue_menu
				build
				cleanup_menu
				break
				;;
			"Quit")
				echo "${RED}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

continue_menu() {
	echo "\n${PURPLE}Ready to build${NC}"
	echo "${PURPLE}You can modify the code now before building${NC}\n"
	PS3='Would you like to continue building? '
	OPTIONS=(
		"Continue"
		"Checkout Commit"
		"Checkout Pull Request"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Continue")
				break
				;;
			"Checkout Commit")
				checkout_commit_menu
				break
				;;
			"Checkout Pull Request")
				checkout_pr_menu
				break
				;;
			"Quit")
				echo "${PURPLE}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

checkout_commit_menu() {
	echo "\n${PURPLE}What commit would you like to checkout?${NC}"
	commit_hash=$(printf '%s' 'Commit Hash: ' >&2; read x && printf '%s' "$x")
	git checkout "$commit_hash"
	if [ $? -ne 0 ]; then
		echo "\n${RED}Could not find the specified commit${NC}\n"
		continue_menu
	fi 
}

checkout_pr_menu() {
	echo "\n${PURPLE}What pull request would you like to checkout?${NC}"
	pr_id=$(printf '%s' 'Pull Request ID: ' >&2; read x && printf '%s' "$x")
	branch_name=$(printf '%s' 'New Branch Name: ' >&2; read x && printf '%s' "$x")
	git fetch origin pull/$pr_id/head:$branch_name
	if [ $? -ne 0 ]; then
		echo "\n${RED}Could not find the specified pull request${NC}\n"
		continue_menu
	fi 
	git switch $branch_name
}

release_type_menu() {
	PS3='What release type would you like to build? '
	OPTIONS=(
		"Release"
		"Debug")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Release")
				BUILD_MODE="Release"
				break
				;;
			"Debug")
				BUILD_MODE="Debug"
				break
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

frontend_menu() {
	PS3='What frontend would you like to use? '
	OPTIONS=(
		"SwiftUI"
		"SDL")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"SwiftUI")
				FRONTEND_MODE="SwiftUI"
				break
				;;
			"SDL")
				FRONTEND_MODE="SDL3"
				break
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

cleanup_menu() {
	echo "\n${GREEN}The script has completed${NC}"
	
	PS3='Would you like to delete the source folder? '
	OPTIONS=(
		"Quit"
		"Delete")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Quit")
				echo "${PURPLE}Quitting${NC}"
				exit 0
				;;
			"Delete")
				echo "${PURPLE}Cleaning up${NC}"
				rm -rf hydra
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

introduction
main_menu
