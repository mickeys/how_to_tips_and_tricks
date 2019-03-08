# Using Gas Mask to target a development machine

[Gas Mask](https://github.com/2ndalpha/gasmask) is a free, open-source hosts file manager we use to point `production.yourdomain.com` to an appropriate environment (typically production, staging, or some other instance).

When run as a normal macOS user you will get repeated pop-ups asking for permission to change the hosts file every time your VPN kicks in and changes the network state; for me it was every time my laptop woke up. Here's my work-around:

* Make a copy of the configurations you've defined. I used an open text editor buffer.

* Add the following to your `.bashrc` or `.bash-profile`. To have it take effect in the current terminal window `source THAT_FILE`.

```bash
MASK='/Applications/Gas Mask.app/Contents/MacOS/Gas Mask'
if [ -x "$MASK" &> /dev/null ] ; then
	alias mask="sudo -b \"$MASK\""
fi
```

* Run `mask` and re-create your configs (as this version is running as root and doesn't see your previous, non-root configs).

## minimal hosts files

production:

```
127.0.0.1 localhost
255.255.255.255	broadcasthost
::1 localhost
fe80::1%lo0	localhost
5.6.7.8 production.yourdomain.com # IP of production instance
```

development:

```
127.0.0.1 localhost
255.255.255.255 broadcasthost
::1 localhost
fe80::1%lo0	localhost
1.2.3.4 production.yourdomain.com # IP of dev instance
```
