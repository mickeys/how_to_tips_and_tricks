# jiracron - schedule repeating tasks with JIRA

| TL;DR |
|:---|
| Here's how to programattically create JIRA tickets on a weekly schedule, perfect for those repeating tasks which ought to be kicked off by a computer. You can even call `jiracron` from real _cron_, making the whole thing hands-off. Rather than just throw source code at you I'll walk you through the design and implementation, and _then_ show the source code.<br>&nbsp;<br>In a nutshell, the design process (and this discussion) look like:<br>&nbsp;<br>(3. iterate across the`tasks` data structure<br>&nbsp;&nbsp;(2. use `curl` to communicate with JIRA<br>&nbsp;&nbsp;&nbsp;&nbsp;(1. build JIRA REST API URLs to create a ticket )))<br>&nbsp;<br>Following that structure, this paper will design and implement jiracron using this "inside-out" pattern.|

## Introduction

**Scenario:** Your process includes tasks which repeat during the week. These tasks need to be routed to some responsible party, handled, possibly assigned to others in a chain of ownership, and marked when completed.

Generally, until the pain becomes too acute, the solution is to create tickets by hand, often from some cheat-sheet with information to be included with the tickets. Easy to forget, easy to create tickets with some necessary information missing; overall a frustrating, unrewarding, error-prone attempt at a solution.

Cloning the tickets you made last time isn't without issues either: you have to delete responses and ensure you're cloning the correct tickets and not forgetting any.

**Solution:** I'll describe (and provide source code) for an automated ticket-creation system that interfaces with the reasonably ubiqutious [JIRA](https://www.atlassian.com/) bug-tracking ticket system. By the end of this document you should, at minimum, have a working understanding of how to programattically use the JIRA REST API to create and update tickets. You can customize the `tasks` data structure to schedule your things as long as you tailor the creation commands to reflect the schema of your JIRA tickets. Each of these elements will be explained.

![](./images/xkcd-is_it_worth_the_time_2x_smaller.png)

## Prerequisites

If you want to play along, hitting your own test JIRA instance (`$JIRA`), you'll need to have your JIRA credentials set (and perhaps persistent) in following environmental manner.

```
$ export JIRA='http://jira.example.com
$ export JIRA_USER='username'
$ export JIRA_PWRD='password'
$
$ echo -n "${JIRA_USER}:${JIRA_PWRD}" | base64
dXNlcm5hbWU6cGFzc3dvcmQ=
```

We'll be using the `base64` output shortly. Why am I not using the typical `--user username:password` construction? Because special characters, such an exclamation point in the password can cause issues (depending upon the software and version used). Better to armor the credentials.

Starting with the simplest interaction, consider the following example. (Note that the `base64` output, generated above, is used here as the authorization payload.) This `curl` command passes a URL to `$JIRA` which causes all tickets assigned to `$JIRA_USER` to be returned (in JSON format).

```
$ curl -D- -X GET \
	--header 'Authorization:Basic dXNlcm5hbWU6cGFzc3dvcmQ=' \
	--header 'Content-Type:application/json' \
	"https://${JIRA}/rest/api/2/search?jql=assignee=${JIRA_USER}"
```

which _should_ return a response the beginning of which looks something like:

```
{"expand":"schema,names", "startAt":0, "maxResults":50, "total":37,
"issues":[{"expand":"operations, versionedRepresentations, editmeta,
changelog, renderedFields", "id":"436439", "self":"https://...
```

Getting this simple case working ensures you've got all the pieces properly set up. We don't really care about the response, as long as there is a valid, error-free response. Now we can move on to creating tickets, not just reading them.

## Build JIRA REST API URLs to create a ticket 

### JIRA REST API

For each web page you visit there's a corresponding URL. Visiting a website may start with a URL like

```
https://example.com/
```

but when you are logging in the URL changes to:

```
https://example.com/login?user=USERNAME&password=PASSWORD
```

and the URL reflects the state of your arrival to the next page:

```
https://example.com/welcome.html
```

The state of each step in the process (of logging in, for example) is reflected in the URL; this is known as [REST](https://en.wikipedia.org/wiki/Representational_state_transfer). This provides us with a mechanism to drive other software. For example, most people create JIRA tickets with a web browser, clicking on pull-downs to select values, entering text into boxes, and then hitting the 'create' button. That works for _ad hoc_ needs, but there's another way: JIRA has an application programmatic interface (API) that conforms to the REST standard, so we can write a program to create tickets as long as we know how to talk REST.

### JIRA issue structure

All of the hard-coded work of creating tickets radiates outwards from the structure of an individual issue Your JIRA administrator has selected the information your group needs to encapsulate a process, or has picked from a selection of well-known defaults (for different software development lifecycle methodologies). _Which_ has been picked doesn't matter, just that you understand that the structure of issues drives how you need to use the JIRA REST API and how to customize the your commands.

At minimum, every JIRA issue contains the following:

| data element | explanation |
|:---|:---|
| `key` | project identifier, e.g. 'GIR' |
| `issuetype` | 'task', 'bug', etc. |
| `name` | at-a-glance name for the issue, e.g. 'Hungry giraffes' |
| `summary` | a one-sentence clarifying statement, e.g. 'Regular feeding schedule needed for giraffes' |
| `description:` | free-form data for multi-paragraph communication with those handling the issue |

Creating a program that uses the JIRA REST API starts with one manually crafting and testing URLs that perform the desired actions and then supplying those URLs with needed values. (Using cooking as an analogy, recipe first and going shopping for ingredients thereafter.) 

### Wrapping up parameters to pass back and forth

To pass our commands to JIRA programmatically we need to wrap the issue data elements in some unifying container. In exactly the same manner as information is passed to and from web servers, we'll be using JSON ([JavaScript Object Notation](https://en.wikipedia.org/wiki/JSON)) to drive JIRA. JSON isn't terribly easy to get right, but we have some tools to help. (Rather than show you all the broken paths to malformed JSON, let's short-cut to how to get it right.)

The JSON needed to carry the minimum data elements listed is this:

```
{"fields":{"project":{"key":"KEY"},"issuetype":{"name":"TYPE"},"summary":"SUMMARY","description":"DESC"}}
```

It's hard to tell from such a trivial example, but there are real pitfalls to having to manage all those double-quotes and properly escaping strings which contain quotes and other special characters. Trust me for the moment when I say that using `jq` will ultimately be much, much easier, as you develop your code to take variables.

```
jq --null-input --compact-output "{fields: {project: {key:\"KEY\"}, \
  issuetype:{name:\"TYPE\"}, summary:\"SUMMARY\", description:\"DESC\" }}"
```

Remember that the exact data elements you'll need for your issue-creation will need to match the decisions made for the structure of your project. You may have required fields, etc.

## Use curl to communicate with JIRA

You've gotten `curl` to "GET" data from your JIRA server in the prerequisites phase, now let's "POST" a ticket-creation command formatted by `jq`:

```
jq ... | curl --silent -D- -X POST ... https://${JIRA}/rest/api/2/issue/ --data @-
```

When you try the command, with the "..." replaced by the full command-line arguments shown above, you should see a reply that looks like:

```
 {"id":"456","key":"GIR-001","self":"https://jira.example.com/rest/api/2/issue/456"}/;Secure
```

JIRA ticket `GIR-001` has been successfully created!

## Iterate across the`tasks` data structure

If we did nothing more than capture the ticket requirements in a file of jq and curl commands it'd be more pleasant, fast, and less error-prone than manually creating tickets via the web-based user interface. But we can do so much more!

Here I'll present a simple data structure to drive the ticket creation based upon day-of-week, so any personal or business process can be harnessed to the scripting you've seen thus far. (I leave it as an exercise to the reader to extend this to a monthly or annual scheduler.)

```
declare tasks=(
#	'SMTWRFS|name|summary|description'
	'-M-----|Count giraffes|Ensure giraffe population|First thing after the weekend...'
	'-----F-|Check food supply|Order food for next week|If we have less than 200 kilos...'
)
```

The first item shows on which days a task should have a JIRA ticket created for it. The format is a representation of a week, starting at Sunday, with a hyphen `-` denoting it should **not** be done on that day.

The jiracron source code checks the current day of the week and creates tickets appropriately. (It does _not_ keep track of previous runs; if you run it twice in one day it'll have created two of each task ticket.)

## Using cron to schedule your ticket-creation

Every modern operating system provides some way to run a piece of software automatically; on UNIX and UNIX-like systems (including macOS and Windows Subsystem for Linux) that scheduler is called `cron`. Refer to your OS's documentation for appropriate instructions for scheduling jiracron.

## Summary and source code

We've seen how to create REST API URLs, how they mirror the internal structure of JIRA issues, how to use `jq` and `curl` to programmatically create JIRA tickets, and how to use a data structure to capture business process (on a weekly granularity).

The [jiracron source code](./jiracron.sh) shows these steps in action. Remember, you'll have to edit it to match the structure of the JIRA project with which you're working.