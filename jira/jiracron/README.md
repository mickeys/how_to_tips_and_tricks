# jiracron - schedule repeating tasks with JIRA

**Scenario:** Your process includes tasks which repeat during the week. These tasks need to be routed to some responsible party, handled, possibly assigned to others in a chain of ownership, and marked when completed.

Generally, until the pain becomes too acute, the solution is to create tickets by hand, often from some cheat-sheet with information to be included with the tickets. Easy to forget, easy to create tickets with some necessary information missing; overall a frustrating, unrewarding, error-prone attempt at a solution.

**Solution:** I'll describe (and provide source code) for an automated ticket-creation system that interfaces with the reasonably ubiqutious [JIRA](https://www.atlassian.com/) bug-tracking ticket system. By the end of this document you should, at minimum, have a working understanding of how to programattically use the JIRA REST API to create and update tickets. You can customize the `tasks` data structure to schedule your things as long as you tailor the creation commands to reflect the schema of your JIRA tickets. Each of these elements will be explained.

## JIRA REST API

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

## JIRA ticket structure

It all radiates out from the structure of an individual ticket, or task. Your JIRA administrator has selected the information your group needs to manage tickets, or picked from a selection of well-known defaults (for different software development lifecycle methodologies). _Which_ has been picked doesn't matter, just that you understand that the structure of tickets drives how you need to use the JIRA REST API and how to customize the tickets.

Creating a program that uses the JIRA REST API starts with one manually crafting and testing  URLs that perform the actions desired and then supplying those URLs with needed values. Using cooking as an analogy, recipe first and going shopping for ingredients thereafter.

Starting with the simplest interaction, consider the following. First I echo my authorization credentials into `base64` and use the output as a parameter to the `curl` command (which passes a URL to `$JIRA` which causes all tickets assigned to $JIRA_USER to be listed in a JSON format).


```
$ echo -n "${JIRA_USER}:${JIRA_PWRD}" | base64
dXNlcm5hbWU6cGFzc3dvcmQ=
$
$ curl -D- -X GET \
	--header 'Authorization:Basic dXNlcm5hbWU6cGFzc3dvcmQ=' \
	--header 'Content-Type:application/json' \
	"https://${JIRA}/rest/api/2/search?jql=assignee=${JIRA_USER}"
```

Why am I not using the typical `--user username:password` construction? Because special characters, such an exclamation point in `$JIRA_PWRD` can cause issues (depending upon the software and version used). Better to armor - but not protect - the credentials.