#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# ghUpdateCheck -- Github update checker()
#
# Because of the architectural nature of the git source code management system
# there's no inherent concept of 'version number' so there's no trivial way to
# check to see whether there's a later version of code to trigger an update.
#
# The following function uses the Github REST API to get the contents of the
# last commit and compares it with a local copy (by calculating SHA hashes). If
# the two differ the assumption is made that the reason is a subsequent commit
# has happened and the user should update the local copy.
#
# Return is 0 success (up-to-date) or 1 failure (local file needs updating).
# -----------------------------------------------------------------------------
ghUpdateCheck () {
	local LOGIN="$1"					# 'username'
	local PW_OR_KEY="$2"				# 'password' or a Github API key
	local GH="$3"						# 'api.github.com/repos'
	local OWNER="$4"					# repo owner username, for URL
	local REPO="$5"						# repository name
	local FP="$6"						# path to the file within repo
	local FN="$7"						# filename to be checked
	local BRANCH="$8"					# 'master' or some other branch

	# -------------------------------------------------------------------------
	# Note: the 'accept' header is sent to future-proof this code for when the
	# default API level changes; see developer.github.com/v3/
	# -------------------------------------------------------------------------
	local=$( shasum < "${BASH_SOURCE[0]}" )

	remote=$( curl -u "${LOGIN}:${PW_OR_KEY}" \
		--header 'Accept: application/vnd.github.v3+json' \
		"https://${GH}/${OWNER}/${REPO}/contents/${FP}/${FN}?ref=${BRANCH}" 2>/dev/null \
		| jq --raw-output '.content' | base64 -D | shasum )

	[[ "${local%% *}" != "${remote%% *}" ]]	# 0 = is latest | 1 = update needed
}

# -----------------------------------------------------------------------------
# Example of ghUpdateCheck() being called and return code analyzed.
# -----------------------------------------------------------------------------
thisFilename="$(basename ${BASH_SOURCE[0]})"

if ghUpdateCheck "${OWNER}" "${GH_AKEY}" \
	'api.github.com/repos' \
	'mickeys' \
	'how_to_tips_and_tricks' 'github/github_update_checker' \
	"${thisFilename}" 'master' ; then
		echo "There's a later version of ${thisFilename} available."
	else
		echo "You're running the latest version of ${thisFilename}."
	fi
exit
