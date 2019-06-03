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

## Easy-to-read test status email subject lines

When something is automated the test runs pile up and can get ignored. So I want the email subject lines to scream out "FAILURE". The most modular way I could think of was passing the test output through a script which generates the subject lines. I came up with `~/bin/boolean.sh`, referred to in the crontab above.

The script is called with (1) a human-readable test suite name and (2) the email recipient.

```
#!/bin/bash
# -------------------------------------------------------------------------------
# email command output with success or failure noted in the subject line
# -------------------------------------------------------------------------------
THIS=$( basename ${BASH_SOURCE[0]} )	# the name of this script
if [[ $# -ne 2 ]] ; then echo "usage: $THIS 'test name' 'recipient'" ; exit ; fi

OUT=$(mktemp) || { echo "Failed to create temp file; quitting." ; exit 1 ; }
cat > "$OUT"							# capture STDIN to temporary file

if grep "error" < "$OUT" 2>&1 > /dev/null ; then r="FAILURE" ; else r="SUCCESS" ; fi

cat "$OUT" | mailx -E -s "${r} -- ${1}" "${2}"
```

## Conclusion

Now my email contains messages with subjects "SUCCESS -- foo.rb" and "FAILURE -- foo.rb" which are easier to notice, I can filter successes away so only failures appear on my main page, etc.