# A Github update-checker

## Problems statement

You've written some piece of code that gets distributed to your friends or co-workers. They're not the code-saavy types to clone the Github repo but instead just grab the standalone app. You make some changes and `git commit`, sure, but how do the others know that there's a newer version to be had?

## Solution overview

Github provides a REST API &#8212; whether it's the public [github.com](https://github.com) or a private, secure company repository hierarchy &#8212; that lets you reach in tweak things. The [developer API documentation](https://developer.github.com/v3/) is the place to start should you wish to extend your understanding of this note.

### Authorization credentials

Whereas some of Github is available to "unauth'd users" &#8212; those who have neither allowed a cookie to be set nor logged in &#8212; the REST API requires authentication.

You have two choices, use a password or an API key. The API key can be created with restricted access permissions, and doesn't expose your login password to others, so this is the preferred method. Create an API key to allow others to access your repos at XYZZY

### Language-agnosticism

The REST API is available to almost every programming language. This example happens to be written in bash, that ubiquitous interface, but it's reasonably trivial to implement in whatever you're using at the moment.

That having been said, let's dive into the code:

I've encapsulated the update-checker into a function, `ghUpdateCheck`. The first section shows the function call along with some hints on what's expected of the parameters. Note please that there's a difference between your login and your owner strings.

```
ghUpdateCheck () {
	local LOGIN="$1"					# 'username'
	local PW_OR_KEY="$2"				# 'password' or a Github API key
	local GH="$3"						# 'api.github.com/repos'
	local OWNER="$4"					# repo owner username, for URL
	local REPO="$5"						# repository name
	local FP="$6"						# path to the file within repo
	local FN="$7"						# filename to be checked
	local BRANCH="$8"					# 'master' or some other branch
```

### Hashes as unique identifiers

The command `shasum` generates a "hash", converting the contents of the file into a reasonably unique string like "da39a3ee5e6b4b0d3255bfef95601890afd80709". (There are "hash collissions" but they're reasonably unlikely.) Change anything in the file and the resultant hash changes.

### The update-check function

First we generate a hash value for our local copy the running program, which can be found with the bash environment variable `BASH_SOURCE[0]`. That hash is stored in `l_sha`.

```
l_sha=$( shasum < "${BASH_SOURCE[0]}" )
```

Next we grab the contents of the latest commit of this file from the Github repo. We provide `curl` with

1. Authentication credentials to gain access to the file we're checking.
2. A header which specifies that we want to use version 3 of the REST API; someday when Github moves to version 4 this will still work because we're not accepting the default version. When version 3 is retired, if ever, we'll be forced to update this command to communicate however version 4 demands.
3. A URL that specifies which server, repo, file, and file branch we're using. By specifying `/contents/` at the right location within the URL we'll be given the file contents (as opposed to any of the other information for which we can ask).

```
remote=$( curl --user "${LOGIN}:${PW_OR_KEY}" \
	--header 'Accept: application/vnd.github.v3+json' \
	"https://${GH}/${OWNER}/${REPO}/contents/${FP}/${FN}?ref=${BRANCH}" 2>/dev/null \
	| jq --raw-output '.content' | base64 -D )
```

Because the contents are returned to us as an armored base 64 blob wrapped in a JSON data structure, we have to first unwrap the JSON (with the `jq` command) and then decode the blob (with `base64 -D`). Then the file contents are stored within the `remote` variable.

`r_sha` holds the calculation of the remote hash value.

```
r_sha=$( shasum < "$remote" )
```

Lastly we return the result of comparing the local and remote hash values. If they're the same, meaning the running program is up-to-date, we return the UNIX success value of 0. If they're different, meaning the latest commit has some changes and an update is called for, we'll return a 1.

```
[[ "${l_sha%% *}" != "${r_sha%% *}" ]]
```

## Using ghUpdateCheck() &#8212; an example

First we extract the filename part of the whole path to the running program.

```
thisFilename="$(basename ${BASH_SOURCE[0]})"
```

Then we call ghUpdateCheck() with the proper parameters, wrapped in an `if` statement, which offers two outcomes.


```bash
if ghUpdateCheck "${OWNER}" "${GH_AKEY}" \
	'api.github.com/repos' \
	'mickeys' \
	'how_to_tips_and_tricks' 'github/github_update_checker' \
	"${thisFilename}" 'master' ; then
		echo "There's a later version of ${thisFilename} available."
	else
		echo "You're running the latest version of ${thisFilename}."
	fi
```

Because you've got a copy of the latest commit of the file in `$remote` 