# ping & rsync rescue copying over a bad connection

I'm trying to copy a directory from a server while I have a bad connection. The copy keeps dying. What's a geek to do?

Here's a two-part solution (for macOS). Fire up your Terminal.app and get crocking!

## copying that preserves progress

Instead of using operating system drag-and-drop file copying use rsync to copy the directory. If the connection drops [rsync](https://en.wikipedia.org/wiki/Rsync) will resume, saving your progress thus far.

```
$ rsync --progress -avz /path/to/source/ /path/to/destination
```

Note the `\` trailing the source path; that'll prevent a directory being created inside the destination directory.

If you want to copy using [ssh](https://en.wikipedia.org/wiki/Secure_Shell) instead of mounting the source directory try the following:

```
$ rsync --progress -v -e ssh user@X.X.X.X:/path/to/source/ /path/to/destination
```

Okay, so now you've preserving your progress. How to reconnect automatically, without your needing to constantly watch the connection and run low on beauty sleep?

## reconnecting a down network

Save the following in a file to run at the same time you're doing an rsync; this'll use [ping](https://en.wikipedia.org/wiki/Ping_(networking_utility)) to detect a disconnect and cycle your Wi-Fi.

```bash
#!/bin/bash
light_red='\e[1;91m%s\e[0m\n'
light_green='\e[1;92m%s\e[0m\n'

while [ 1 ]
do
	t=$( date "+%Y-%m-%d %H:%M:%S" )
	ping -c 4 -q 8.8.8.8 > /dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		printf "$light_green" "$t [ OK ]"
	else
		printf "$light_red" "$t [ DISCONNECTED; RESETTING ]"
		networksetup -setairportpower en0 off
		networksetup -setairportpower en0 on
	fi
done
```

## output

Running the script will provide output like (albeit with red and green text, which github MarkDown doesn't honor):

```
$ ./reconnect.sh<br>
2019-03-08 00:25:44 [ OK ]
2019-03-08 00:25:47 [ DISCONNECTED; RESETTING ]
2019-03-08 00:25:53 [ OK ]
```

## conclusion

This solution is specific to macOS. If you tweak it for the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/) or another UNIX please let me know the exact commands required to cycle your Wi-Fi and I'll update this script to check for your operating system.
