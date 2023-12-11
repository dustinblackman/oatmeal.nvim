#!/usr/bin/env bash

oatmeal --help | sd ' ' '\n' | grep '\-\-' | grep -v -E '(version|help)' | sd '\-\-' '' | sort |
	awk '{print "\""$1"\","}' | pbcopy

echo "Copied to clipboard"
