# Ruby, RSpec, cron, and email

## Problem statement

I have some Ruby RSpec tests that I want to run locally (on my laptop) on a regular basis, getting emails with the test status and output.

## Running Ruby RSpec on a periodic basis

The most lightweight solution is to use the UNIX `cron` utiliity. I populated the "crontab" file in several steps:

1. run `rvm cron setup` to dump my Ruby environment variables in a cron-usable format.
2. run `crontab -e` to edit the crontab file with my job specifics

```
# 'rvm cron setup' generated the following:
#sm start rvm
PATH="/Users/me/.rvm/gems/ruby-2.3.3/bin:..."
GEM_HOME='/Users/me/.rvm/gems/ruby-2.3.3'
GEM_PATH='/Users/me/.rvm/gems/ruby-2.3.3:...'
MY_RUBY_HOME='/Users/me/.rvm/rubies/ruby-2.3.3'
IRBRC='/Users/me/.rvm/rubies/ruby-2.3.3/.irbrc'
RUBY_VERSION='ruby-2.3.3'
#sm end rvm
MAILTO="person@example.com"
# +------------- min (0 - 59)
# | +----------- hour (0 - 23)
# | | +--------- day of month (1 - 31)
# | | | +------- month (1 - 12)
# | | | | +----- day of week (0 - 6) (where 0 = Sunday and 6 = Saturday)
# | | | | |
# - - - - - -------------------------------------------------------------------
0 * * * * cd /dir ; VAR=value /.../rspec pathto/foo.rb 2>&1 | ~/bin/boolean.sh "foo.rb" "${MAILTO}"
```

## Easy-to-read statuses for email, SMS, and Slack

When something is automated the test runs pile up and can get ignored. So I want the status subject lines to scream out "FAILURE". The most modular way I could think of was passing the test output through a script which generates the subject lines. I came up with `~/bin/boolean.sh`, referred to in the crontab above.

The script is called with (1) a human-readable test suite name and (2) the email recipient.

```
#!/bin/bash
# -------------------------------------------------------------------------------
# command output w/ success | failure noted in (1) sms and (2) email subject line
#
# ------------+------------------------- #
# Carrier     | Domain Name              #
# ------------+------------------------- #
# AT&T        | @txt.att.net             #
# Cricket     | @mms.mycricket.com       #
# Nextel      | @messaging.nextel.com    #
# Qwest       | @qwestmp.com             #
# Sprint      | @messaging.sprintpcs.com #
# T-Mobile    | @tmomail.net             #
# US Cellular | @email.uscc.net          #
# Verizon     | @vtext.com               #
# Virgin      | @vmobl.com               #
# ------------+------------------------- #
#
# -------------------------------------------------------------------------------
THIS=$( basename "${BASH_SOURCE[0]}" )	# the name of this script
if [[ $# -lt 2 ]] ; then echo "usage: $THIS 'test name' recipient [sms]" ; exit ; fi

OUT=$(mktemp) || { echo "Failed to create temp file; quitting." ; exit 1 ; }

cat > "$OUT"							# capture STDIN (cmd output) to tempfile

if grep "error" < "$OUT" 2>&1 > /dev/null ; then r="FAILURE" ; else r="SUCCESS" ; fi

# send email regardless of status
cat "$OUT" | mailx -n -E -s "${r} -- ${1}" "${2}"

# on *failures* send alert(s)
if [ "$r" = 'FAILURE' ] ; then
	# ---------------------------------------------------------------------------
	# SMS if an optional address was passed
	# ---------------------------------------------------------------------------
	if [ -n "$3" ] ; then mailx -n -s "${r} -- ${1}" "$3" < /dev/null ; fi
	# ---------------------------------------------------------------------------
	# slack for all failures
	# ---------------------------------------------------------------------------
	curl -X POST --data-urlencode \
	"payload={\"mrkdwn\": true, \"text\": \"*${r}* - \`${1}\`\", \"icon_emoji\": \":cron:\", \"username\": \"cron\"}" \
	https://hooks.slack.com/services/...
fi
```

## Conclusion

Now my email contains messages with subjects "SUCCESS -- foo.rb" and "FAILURE -- foo.rb" which are easier to notice, I can filter successes away so only failures appear on my main page, etc.