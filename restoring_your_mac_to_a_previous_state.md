# Restoring your Mac to a previous state

| **tl;dr**|
| :--- |
| If you can require your Mac's operating system or installed applications or files to be in a specific working state you can create a [snapshot](https://en.wikipedia.org/wiki/Snapshot_(computer_storage)) of how it's set up at a particular moment in time to be able to restore should you break things. |


**Backstory**: I'd worked long and hard to understand a technical configuration needed for a specific software development project. I created a shell script to automate the complex and non-trivial installation and configuration process. Sometime thereafter I did _something_ to break this fragile house of cards and spent several days debugging and fixing the problem. Then I researched how to never have to undergo that pain again. You're welcome.

![xkcd](./images/xkcd_1718.png)<br>[_Explanation_](https://www.explainxkcd.com/wiki/index.php/1718:_Backups)

**Requirements**: You need to be minimally comfortable working with a command-line environment within the [Terminal](https://en.wikipedia.org/wiki/Terminal_(macOS)) application, your Mac's hard disk must be formatted with the Apple File System (APFS) (available on macOS version "High Sierra" (10.3) and later), and you need enough space on your disk. (Aside: Apple uses this technique to create a backup point to allow you to recover from an operating system upgrade that goes wrong. When macOS runs low on disk space it'll thin out your store of snapshots, so there's that.)

**Disclaimers**: Snapshots should _not_ be your only or primary method of data backup. Ensure that you have a comprehensive system of local and remote backups in place to handle hard disk failure, loss or theft, and catastrophic file where you store your computer and local backups. Also, while this technique has worked for me, I disclaim any liability for issues you may have following these instructions.

**Timing decisions**: I take snapshots when I have a functioning configuration in place, especially before I'm about to embark on upgrading or changing software. 

## Does your hard disk qualify for snapshotting?

Open Terminal.app. When it's ready to be interacted with you'll see a `$` prompt.

To determine whether your hard disk qualifies for snapshotting type `diskutil list | grep 'HARD_DISK_NAME'` substituting your hard disk's name, typically "Macintosh HD".

```shell
$ diskutil list | grep 'Macintosh HD'
   1:                APFS Volume Macintosh HD            398.8 GB   disk1s1
$
```

If you see "APFS" then continue on. If not, I'm sorry but this technique isn't available to you; you'll have to find some other backup and restore scheme.

## Creating a snapshot

In the Terminal type:

```shell
$ tmutil snapshot
Created local snapshot with date: 2019-03-09-115226
$
```

The snapshot creation process takes but a few seconds.

Verify that a snapshot creating by typing:

```shell
$ tmutil listlocalsnapshots /
com.apple.TimeMachine.2019-03-09-115226
$
```

You read right, the snapshot is of the format used by Apple's [Time Machine](https://en.wikipedia.org/wiki/Time_Machine_(macOS)).

## Preserving local files before a restore

Restoring to the time with a snapshot means that everything you've changed since then will be wiped out. You'll want to identify those files and move them to another hard disk or cloud storage before restoring.

Get the date of the last snapshot with the "tmutil listlocalsnapshots" command, shown above. My example shows "2019-03-09-115226". To find all your files changed since then you can type (omit the seconds portion of the timestamp):

```shell
$ touch -t 201903091152 /tmp/timestamp
$ find ~ -newer /tmp/timestamp
[list of files]
$
```

To look all over your Mac, instead of just your directory, substitute `/` for `~` in the example shown.

Take the time to peruse this list of files carefully. Anything you don't preserve by moving them off the hard disk you're about to restore from snapshot will be lost forever.

# Restoring a snapshot

1. Restart your Mac to recovery mode by holding down the Command and 'R' keys while the system starts up, until the Apple logo appears.

1. In the Recovery window select 'Restore From Time Machine Backup' from options shown.

1. Click 'Continue' when the 'Restore From Time Machine' window opens.

1. Select the disk that contains the snapshots from the list shown. Click 'Continue'.

1. Select the snapshot from which you wish to restore from the list shown.

1. When asked, confirm you wish to restore from this snapshot.

A progress bar will show the state of the restore. Your mac will reboot automatically when the restore is done and you can continue working from a previous moment in time