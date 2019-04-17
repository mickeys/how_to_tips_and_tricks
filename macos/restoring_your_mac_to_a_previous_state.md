# Restoring your Mac to a previous state

| **tl;dr**|
| :--- |
| If you can require your Mac's operating system or installed applications or files to be in a specific working state you can create a [snapshot](https://en.wikipedia.org/wiki/Snapshot_(computer_storage)) of how it's set up at a particular moment in time to be able to restore should you break things. |


**Backstory**: I'd worked long and hard to understand a technical configuration needed for a specific software development project. I created a shell script to automate the complex and non-trivial installation and configuration process. Sometime thereafter I did _something_ to break this fragile house of cards and spent several days debugging and fixing the problem. Then I researched how to never have to undergo that pain again. You're welcome.

![xkcd](./images/xkcd_1718.png)<br>xkcd; [_explanation_](https://www.explainxkcd.com/wiki/index.php/1718:_Backups)

**Requirements**: To be able to take advantage of macOS' snapshot functionality the following are required:

* You need to be minimally comfortable working with a command-line environment within the [Terminal](https://en.wikipedia.org/wiki/Terminal_(macOS)) application.
* Your Mac's hard disk must be formatted with the Apple File System (APFS) (available on macOS version "High Sierra" (10.3) and later).
* You need enough space on your disk. (Aside: Apple uses this technique to create a backup point to allow you to recover from an operating system upgrade that goes wrong. When macOS runs low on disk space it'll thin out your store of snapshots, so there's that.)

**Disclaimers**: Snapshots should _not_ be your only or primary method of data backup. Ensure that you have a comprehensive system of local and remote backups in place to handle hard disk failure, loss or theft, and catastrophic file where you store your computer and local backups. Also, while this technique has worked for me, I disclaim any liability for issues you may have following these instructions.

**Warning**: Your local snapshots will be **_deleted_** by an operating system upgrade, as when my test machine went from High Sierra (10.13) to Mojave (10.4).

**Timing decisions**: I take snapshots when I have a functioning configuration in place, especially before I'm about to embark on upgrading or changing software. 

## Does your hard disk qualify for snapshotting?

Open Terminal.app. When it's ready you'll see a `$` prompt.

To determine whether your hard disk qualifies for snapshotting type `diskutil list | grep 'HARD_DISK_NAME'`, substituting your hard disk's name, typically "Macintosh HD".

```shell
$ diskutil list | grep 'Macintosh HD'
   1:                APFS Volume Macintosh HD            398.8 GB   disk1s1
$
```

If you see "APFS" you're all good. If not, I'm sorry but snapshotting isn't available to you; you'll have to find some other backup-and-restore scheme.

## Creating a snapshot

In the Terminal type `tmutil snapshot` to create a snapshot.

```shell
$ tmutil snapshot
Created local snapshot with date: 2019-03-09-115226
$
```

The snapshot creation process takes but a few seconds.

Verify that a snapshot was creating by typing `mutil listlocalsnapshots` to list existing snapshots.

```shell
$ tmutil listlocalsnapshots /
com.apple.TimeMachine.2019-03-09-115226
$
```

You read that right, the snapshot is of the format used by Apple's [Time Machine](https://en.wikipedia.org/wiki/Time_Machine_(macOS)).

## Preserving local files before a restore

Restoring means that everything you've changed since the snapshot was taken will be wiped out. Identify all files changed since that are important to you and move them out of the way - to another hard disk or cloud storage - before restoring.

Get the date of the last snapshot with the "tmutil listlocalsnapshots" command, shown above. My example shows "2019-03-09-115226". To find all your files changed since then you can type (omit the seconds portion of the timestamp):

```shell
$ touch -t 201903091152 /tmp/timestamp
$ find ~ -newer /tmp/timestamp
[list of files]
$
```

To look all over your Mac instead of just your directory substitute `/` for `~` in the command.

Take the time to peruse this list of files carefully. Anything you don't preserve will be lost forever.

# Restoring a snapshot

1. Restart your Mac to "recovery mode" by restarting while holding down both the Command and 'R' keys until the Apple logo appears.

1. Select 'Restore From Time Machine Backup' from the options shown in the Recovery window.

1. When the 'Restore From Time Machine' window opens click 'Continue'.

1. Select the disk that contains the snapshots from the options presented, then click 'Continue'.

1. Select the snapshot from which you wish to restore from the options presented.

1. Confirm to the pop-up which appears that you wish to restore from this snapshot.

A progress bar will show the state of the restore. Your Mac will reboot automatically when the restore is done and then you can continue working starting from a previous, stable, moment in time.

# Miscellany

Delete a local snapshot:

```shell
$ sudo tmutil deletelocalsnapshots 2019-03-09-115226
$
```

Interact with a local snapshot:

```shell
$ sudo mkdir /Volumes/test
$ sudo mount_apfs -o ro -s com.apple.TimeMachine.2019-03-11-155357 / /Volumes/test
```

**Testing note**: I've tested this procedure on macOS High Sierra (10.13), Mojave (10.14), and across a High Sierra to Mojave upgrade; see warning note above.

**TO-DO**: Investigate whether it's possible to migrate a snapshot out of the way - perhaps Google Drive - and restore after an OS upgrade. 