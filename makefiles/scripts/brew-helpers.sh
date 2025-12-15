#!/usr/bin/env bash
# Homebrew helper functions for package management
# Provides CI-aware prompting, version comparison, and package installation/upgrade

# OUTPUT_REDIRECT should be passed from Makefile (e.g., "> /dev/null 2>&1" or empty for verbose)
OUTPUT_REDIRECT="${OUTPUT_REDIRECT:-}"

# prompt_user(question, ci_message)
# Prompts user for input or auto-answers 'y' in CI environments
# Args:
#   $1 - Question to display to user
#   $2 - Message to display in CI mode
# Sets: answer variable with user response or 'y' in CI
prompt_user() {
	if [ -z "$CI" ]; then
		printf "%s" "$1"
		read -r answer
	else
		answer="y"
		echo "CI environment detected, $2"
	fi
}

# version_less_than(v1, v2)
# Compares semantic versions using sort -V
# Args:
#   $1 - First version (e.g., "1.15.0")
#   $2 - Second version (e.g., "1.16.2")
# Returns:
#   0 if v1 < v2, 1 otherwise
version_less_than() {
	[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ] && [ "$1" != "$2" ]
}

# check_brew(exit_code)
# Ensures Homebrew is installed, prompts for installation if missing
# Args:
#   $1 - Exit code to return if user skips installation
# Returns:
#   0 if brew available, specified exit code if skipped
check_brew() {
	if ! command -v brew >/dev/null 2>&1; then
		echo "❌ Homebrew not found"
		prompt_user "Would you like to install Homebrew? [y/N] " "installing Homebrew automatically..."
		if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
			echo "Installing Homebrew..."
			eval "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\" $OUTPUT_REDIRECT"
			# Verify installation succeeded
			if ! command -v brew >/dev/null 2>&1; then
				echo "⚠️  Homebrew installation completed but brew command not available"
				echo "💡 You may need to add Homebrew to your PATH"
				return "$1"
			fi
		else
			echo "Installation skipped."
			return "$1"
		fi
	fi
}

# brew_install(package, exit_code)
# Installs a package via Homebrew with user confirmation
# Args:
#   $1 - Package name
#   $2 - Exit code (1 = required, 0 = optional)
# Returns:
#   0 on success, exit code on failure/skip
brew_install() {
	check_brew "$2" || return $?
	if command -v brew >/dev/null 2>&1; then
		prompt_user "Would you like to install $1 using Homebrew? [y/N] " "installing $1 automatically..."
		if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
			echo "Installing $1 via Homebrew..."
			if eval "brew install $1 $OUTPUT_REDIRECT"; then
				# Verify installation succeeded
				if brew list "$1" >/dev/null 2>&1; then
					echo "✅ $1 installed successfully"
					return 0
				else
					echo "⚠️  Installation completed but package not found in brew list"
					if [ "$2" = "1" ]; then return 1; fi
				fi
			else
				echo "❌ Failed to install $1"
				if [ "$2" = "1" ]; then return 1; fi
			fi
		else
			echo "Installation skipped."
			if [ "$2" = "1" ]; then return 1; fi
		fi
	else
		return "$2"
	fi
}

# brew_upgrade(package, exit_code)
# Upgrades a package via Homebrew, installs if not present
# Args:
#   $1 - Package name
#   $2 - Exit code (1 = required, 0 = optional)
# Returns:
#   0 on success, exit code on failure/skip
brew_upgrade() {
	check_brew "$2" || return $?
	if command -v brew >/dev/null 2>&1 && brew list "$1" >/dev/null 2>&1; then
		prompt_user "Would you like to upgrade $1 using Homebrew? [y/N] " "upgrading $1 automatically..."
		if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
			echo "Upgrading $1 via Homebrew..."
			if eval "brew upgrade $1 $OUTPUT_REDIRECT"; then
				echo "✅ $1 upgraded successfully"
				return 0
			else
				echo "❌ Failed to upgrade $1"
				if [ "$2" = "1" ]; then return 1; fi
			fi
		else
			echo "Upgrade skipped."
			if [ "$2" = "1" ]; then return 1; fi
		fi
	else
		brew_install "$1" "$2"
	fi
}
