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
# Return value is:
#	success - file is up-to-date - empty string
#	failure - file is out of sync - contents of the latest commit
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

	l_sha=$( shasum < "${BASH_SOURCE[0]}" )
	l_sha="${l_sha%% *}"				# get the first token, the hash

	# -------------------------------------------------------------------------
	# Note: the 'accept' header is sent to future-proof this code for when the
	# default API level changes; see developer.github.com/v3/
	# -------------------------------------------------------------------------
	r=$( curl -u "${LOGIN}:${PW_OR_KEY}" \
		--header 'Accept: application/vnd.github.v3+json' \
		"https://${GH}/${OWNER}/${REPO}/contents/${FP}/${FN}?ref=${BRANCH}" 2>/dev/null \
		| jq --raw-output '.content' | base64 -D )

	r_sha=$( echo -n "$r" | shasum )	# calculate remote checksum
	r_sha="${r_sha%% *}"				# get the first token, the hash

	if [[ "${l_sha}" != "${r_sha}" ]] ; then
		echo "${r}"						# here's the latest commit's contents
	else
		echo ''							# all is good; nothing for you to do
	fi
	return 0							# numeric return code ignored
}

# -----------------------------------------------------------------------------
# Example of ghUpdateCheck() being called and handling of the result.
#
# Required: $GH_USER and $PW_OR_KEY are set in your environment.
# -----------------------------------------------------------------------------
thisFilename="$(basename ${BASH_SOURCE[0]})"

update=$(ghUpdateCheck "${GH_USER}" "${PW_OR_KEY}" \
	'api.github.com/repos' \
	'mickeys' \
	'how_to_tips_and_tricks' 'github/github_update_checker' \
	"${thisFilename}" 'master' )

	# -------------------------------------------------------------------------
	# If there's a difference in the hashes for the existing file and the
	# latest commit then ghUpdateCheck() has returned the file contents. Here I
	# temporary file. That having been captured you can
	#
	#   1. swap out the existing file with the new one and force a restart
	#   2. show the user the new file and have them manually examine & decide
	#   3. something else entirely
	# -------------------------------------------------------------------------
	if [ -n "${update}" ] ; then
		tempd=$(mktemp -d) || { echo "Temporary file creation failed."; exit 1; }
		tempf="${tempd}/$(date +%Y%m%d_%H%M%S)_${thisFilename}"
		echo "${update}" >| "${tempf}"
		echo "There's a later version of ${thisFilename} available."
	else
		echo "You're running the latest version of ${thisFilename}."
	fi
exit
