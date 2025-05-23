#!/bin/bash
#
# This calls the "Get A Release By Tag" Github API endpoint.
# https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release-by-tag-name
#

set -euo pipefail

if [[ -z "${GITHUB_API_TOKEN+x}" ]]; then
    echo "The environment variable GITHUB_API_TOKEN is not set."
    echo "Please set GITHUB_API_TOKEN to the value of a Github Personal Access Token and retry."
    exit 1
fi

if [ $# -lt 3 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <owner> <repo> <tag>"
    echo
    echo "where:"
    echo "   <owner>: The repository scope organization. (required)"
    echo "    <repo>: The repository name. (required)"
    echo "     <tag>: The repository tag. (required)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-composable-architecture 1.18.0"
    exit 1
fi

URL="https://api.github.com/repos/$1/$2/releases/tags/$3"

curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer $GITHUB_API_TOKEN" \
     --no-progress-meter \
     $URL
