#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# This script goes through the `tasks` data structure and creates JIRA tickets
# for today, being aware that Friday tickets are scheduled for the following
# Monday. You'll need to tweak the constants and tasks to reflect the structure
# of the specific JIRA project being targeted.
#
# Constants for this JIRA project:
# -----------------------------------------------------------------------------
project='GIR'							# All about giraffes :-)
component='XX'
issueType='Task'
vertical='Zoo Operations'

# -----------------------------------------------------------------------------
# The `tasks` data structure encapsulates everything necessary for creating a
# new JIRA ticket. You can extend this should your JIRA project have more
# required fields.
#
# The first element is a representation of a calendar week, beginning with
# Sunday, where a hyphen `-` denotes the task should *not* be run that day. The
# current source code doesn't check to see whether the alphabetic characters
# actually correspond to the day-of-week, just that they're not a hyphen.
#
# The remaining elements correspond exactly to the structure chosen by the JIRA
# administrator, and must be tailored for each $project. Items of note:
#
#   * Descriptions can be made multi-paragraph by making it a string of the form
#     'Paragraph One\n\nParagraph Two\n\nParagraph Three'
# -----------------------------------------------------------------------------
declare -a tasks=(						# (needs BASH_VERSION >= 4)
#	'SMTWRFS|name|summary|description'
	'-M-----|Count giraffes|Ensure giraffe population|First thing after the weekend...'
	'-----F-|Check food supply|Order food for next week|If we have less than 200 kilos...'
)

# -----------------------------------------------------------------------------
# One feature I wrote in the original codebase was to use a token for repeated
# items, as shorthand. For example, if all 'feeding' were to be done on a
# specific list of animalss it'd be easy to have drift between multiple lists
# of the same thing, so specifying a token 'feed' could be expanded, shown here
# in the `feeding` structure.
#
# Note: associative arrays in bash, which allow mapping a text token, requires
# bash 4 or later (for which I test).
# -----------------------------------------------------------------------------
#((${BASH_VERSINFO[0]} > 3 )) || ( echo "Error: bash 4.0 or later needed; quitting." >&2; exit 1 )
#
## shellcheck disable=SC2034
#declare -A feeding=(					# compound assignment; LHS must be unique
#	[outside]='giraffes,elephants,tigers,lions'
#	[inside]='cobra,voles,butterflies'
#	[pool]='dolphins,piranhas,goldfish'
#)

# -----------------------------------------------------------------------------
# In an attempt to make even easier-to-maintain code I've written makeJsonArray
# so programmers can concern themselves with values, not formatting. Calling
# makeJsonArray dog,fish,bird
# results in [{value:"dog"},{value:"fish"},{value:"bird"}]
# -----------------------------------------------------------------------------
makeJsonArray() {
    local csv="$1"						# expecting A,B,C
	local out=''						# returning [{value:"A"},...]

	# iterate over csv, wrapping each of the values in the necessary JSON
	for i in ${csv//,/ }
	do
		out="$out{value:\"$i\"},"
	done

	# remove trailing comma before returning the array contents
	last=${out#"${out%?}"}				# get the last character
	if [ "$last" = ',' ]; then			# if it's a trailing comma
		out=${out%?}					# remove it
	fi

	echo "[$out]"						# wrap result in array square brackets
}

# -----------------------------------------------------------------------------
# Sanity-check for the required environment variables; quit if any are missing.
# -----------------------------------------------------------------------------
if [ -z "$JIRA_PWRD" ] ; then			# password prompt if not env variable
	echo 'Set environment variable "$JIRA_PWRD" to avoid this prompt in the future.'
	# shellcheck disable=SC2034			# ignore "unused" prompt string
	while read -rp 'Enter your JIRA password: ' JIRA_PWRD ; do
		if [ "$JIRA_PWRD" ]; then break ; fi
	done
fi

for need in JIRA JIRA_USER ; do
	if [ -z "${!need}" ] ; then
		echo "${BASH_SOURCE[0]}: set environment variable ${need} and try again."
		echo -n "${BASH_SOURCE[0]}: example ${need} is "
		case "$need" in
			 'JIRA')
				  echo "jira.example.com"
				  ;;
			 'JIRA_USER')
				  echo "your JIRA username"
				  ;;
#			 *)
#				  ;;
		esac
		exit
	fi
done

# TO-DO: use base64 to armor passwords containing special characters
credentials="--user ${JIRA_USER}:${JIRA_PWRD}"	# shorthand

# -----------------------------------------------------------------------------
# Use `date` to generate some elements we need in scheduling weekly tasks.
# -----------------------------------------------------------------------------
yearLastTwo=$( date +"%y" )				# 2019 --> "19"
weekOfYear=$( date +"%V" )				# {0..51}
intDayOfWk=$( date +"%-u" )				# {0..6}
dayOfWeek=$( date +"%a" )				# "Tue"

# -----------------------------------------------------------------------------
# Remember, on Fridays the next *working* day is Monday.
# -----------------------------------------------------------------------------
if [[ "$dayOfWeek" == 'Fri' || "$dayOfWeek" == 'Sat' || "$dayOfWeek" == 'Sun' ]] ; then
	nextWorkday=3						# weekend: next workday is Monday
else
	nextWorkday=1						# next workday is tomorrow
fi

# Generate the next workday (in a couple of formats)
#tomorrow=$( date -v +"${nextWorkday}d" +"%b %d" )		# "Jan 30"
sortDate=$( date -v +"${nextWorkday}d" +"%Y-%m-%d" )	# "2019-01-30"

t=1										# monotonically increasing ticket number

# -------------------------------------------------------------------------
# Iterate over the `tasks` array, identifying and dispatching only those
# which are scheduled to be done today.
# -------------------------------------------------------------------------
for i in "${tasks[@]}"
do
	# ---------------------------------------------------------------------
	# break each task into components and assign to local variables
	# ---------------------------------------------------------------------
	# shellcheck disable=SC2034
	IFS='|' read -r schedule name summary description <<< "$i"
	tidied="$name task for $sortDate"

	# ---------------------------------------------------------------------
	# Check $schedule, eg '-MTW---', and check whether in the day-of-week
	# position there's anything *but* a '-' (to create that ticket).
	# TO-DO: beef up the checking to ensure that the SMTWRFS is appropriate.
	# ---------------------------------------------------------------------
	if [ "${i:intDayOfWk:1}" = '-' ] ; then continue ; fi

	# ---------------------------------------------------------------------
	# $fixVer, the build targeted by testing, is a string that looks like
	# "YY.WWX" where YY = last two digits of this year, WW = the numeric
	# week of this year, and X = a character specifier if desired. Aware of
	# end-of-week issues, WW will be kicked to the next week on Fridays.
	# ---------------------------------------------------------------------
	if [[ ${summary:(-3)} =~ \((.)\) ]] ; then # e.g. '(A)'
		buildVer="${BASH_REMATCH[1]}"
	else
		buildVer=''
	fi

	if [[ "$dayOfWeek" == 'Fri' ]] ; then
		use=$( date -v +"7d" +"%V" )	# next week
	else
		use="${weekOfYear}"				# this week
	fi

	fixVer="${yearLastTwo}.${use}${buildVer}"

	# ---------------------------------------------------------------------
	# If you want ticket creation to be more verbose:
	# ---------------------------------------------------------------------
	# shellcheck disable=SC2078			# ignore the if [ constant ]
	if [ "" ] ; then					# default to boolean false
		echo "----- ticket $t -----------------------------------------------"
		echo "$tidied"
		for x in name summary description ; do
			printf "\t%10s | %s \n" "$x" "\"${!x}\""
		done
	fi

	# ---------------------------------------------------------------------
	# Special processing for particular tasks...
	# ---------------------------------------------------------------------
	# shellcheck disable=SC2078			# ignore the if [ constant ]
	if [ "" ] ; then					# default to boolean false
		if [ "$name" == 'fresh game for wild cats' ] ; then
			true						# no-op; replace with custom steps
		fi
	fi

	# ---------------------------------------------------------------------
	# JIRA multiSelect fields require setters to provide JSON arrays, so we
	# do that with CSV elements.
	# ---------------------------------------------------------------------
	#fish=$(makeJsonArray "$fish")		# use this if you have multiSelects

	# ---------------------------------------------------------------------
	# Create the JIRA ticket
	# ---------------------------------------------------------------------
	# shellcheck disable=SC2086			# ignore unquoted $credentials glob
	output=$( jq --null-input --compact-output \
		"{fields: {project: {key:\"${project}\"}, name:{value:\"${name}\"}, \
			components:[{name:\"${component}\"}], \
			issuetype:{name:\"${issueType}\"},
			summary:\"${summary}\", \
			description:\"${description}\" }}" \
		| curl --silent -D- -X POST $credentials \
			--header 'Content-Type:application/json'
			"https://${JIRA}/rest/api/2/issue/" --data @- )

	# ---------------------------------------------------------------------
	# Share the state of the ticket creation.
	# ---------------------------------------------------------------------
	if [[ $output =~ ${project}-[[:digit:]]+ ]] ; then
		echo "${t}. Created ${BASH_REMATCH[0]} \"${tidied}\"."
	else
		echo "Error while creating \"${tidied}\"; here's the output:"
		echo "------------------------------------------------------"
		echo "$output"
		echo "------------------------------------------------------"
	fi

	t=$(( t+1 ))						# next human-readable ticket number
done
echo "Server = ${JIRA}"					# pure reassurance :-)