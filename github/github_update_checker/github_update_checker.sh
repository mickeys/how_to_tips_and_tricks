#!/usr/bin/env bash

# -----------------------------------------------------------------------------
#curl -u $_GH_UN:$_GH_UC https://api.github.com/mickeys/dotfiles/blob/master/.bash_ck
#curl -u $_GH_UN:$_GH_UC https://api.github.com/users/mickeys/repos
#curl -u $_GH_UN:$_GH_UC https://api.github.com/repos/mickeys/dotfiles/commits/SHA
#curl -u $_GH_UN:$_GH_UC "https://api.github.com/repos/mickeys/dotfiles/contents/.bash_ck?ref=master"

ghUpdateCheck () {
	local LOGIN="$1"					#
	local PW_OR_KEY="$2"				#
	local SERVER="$3"					#
	local GH_USER="$4"					#
	local REPO="$5"						#
	local PATH_TO="$6"					#
	local A_FILE="$7"					#
	local BRANCH="$8"					#

	remote=$( curl -u "${LOGIN}:${PW_OR_KEY}" \
		--header 'Accept: application/vnd.github.v3+json' \
		"https://${SERVER}/${GH_USER}/${REPO}/contents/${PATH_TO}/${A_FILE}?ref=${BRANCH}" \
		| jq --raw-output '.content' | base64 -D | shasum )
	r_sha=${remote%% *}
	echo $r_sha

	# "${BASH_SOURCE[0]}
	local=$( shasum < "./${BASH_SOURCE[0]}" )
	l_sha=${local%% *}
	echo $l_sha

	if [[ "$r_sha" != "$l_sha" ]] ; then
		echo 'update please'
	else
		echo 'version verified'
	fi
}

ghUpdateCheck "${CK_GH_USER}" "${CK_GH_AKEY}" \
	'code.corp.creditkarma.com/api/v3/repos' \
	'michael-sattler-ck' \
	'ck_how_to' 'jira/sheriff' 'sheriff-cc.sh' 'master'





exit

SERVER='code.corp.creditkarma.com/api/v3/repos' ; REPO= ; PATH_TO= ; A_FILE= BRANCH=

remote=$( curl -u "${LOGIN}:${PW_OR_KEY}" --header 'Accept: application/vnd.github.v3+json' "https://${SERVER}/michael-sattler-ck/${REPO}/contents/${PATH_TO}/${A_FILE}?ref=${BRANCH}" | jq --raw-output '.content' | base64 -D | shasum )
r_sha=${remote%% *}
echo $r_sha

# "${BASH_SOURCE[0]}
local=$( shasum < ./sheriff-cc.sh )
l_sha=${local%% *}
echo $l_sha

if [[ "$r_sha" != "$l_sha" ]] ; then
	echo 'update please'
else
	echo 'version verified'
fi

