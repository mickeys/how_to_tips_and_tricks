# Deep-linking into Slack

How awesome would it be to have hyperlinks in your documents which directly refer to Slack channels and participants? Here's how to construct those URLs.

| NOTE |
|:---|
| Sample hyperlinks below will **not** appear "live" in Github-hosted documents; it's being filtered for your convenience. The URL syntax _is_ correct and _will_ work in other documents. |

## Getting your team_id

Open up `yourdomain.slack.com` in a web browser and then use the developer tools to search for `team_id` in the source. In the "common boot data" Javascript "boot_data" section you'll find something like  `"team_id":"T12345678"`.

## Getting a channel ID

Right-click on the desired channel and 'Copy Link'. You'll get something like:

`https://yourdomain.slack.com/messages/C12345678`

![](./images/slack_channel_link.png)## Getting a user ID

Right-click on the desired user and 'Copy Link'. You'll get something like:

`https://yourdomain.slack.com/messages/U12345678`

![](./images/slack_human_link.png)
## Putting it all togetherDeep links into Slack are of the form:

`slack://channel?team=TEAM_ID&id=SPECIFIC_ID`

so, using the above sample values, a deep link to a channel would be

`slack://channel?team=T12345678&id=C12345678`

and to a user would be:

`slack://channel?team=T12345678&id=U12345678`

You can paste these URLs into Microsoft Word or Confluence link elements, or directly into HTML documents:

```
<a href="slack://channel?team=T12345678&id=C12345678">#channel</a>
<a href="slack://channel?team=T12345678&id=U12345678">@user</a>
```

or into Markdown (although these links will be rendered as "dead" text rather than "live" links on Github-hosted systems):

```
[`#channel`](slack://channel?team=T12345678&id=C12345678)
[`@user`](slack://channel?team=T12345678&id=U12345678)
```

There you go! Deep links into Slack.