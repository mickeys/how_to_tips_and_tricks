# Split and cut video segments with ffmpeg

| So this happened... | |
| :--- | :--- |
| My wife, _the_ crazy cat lady, is a great fan of social media.<br>&nbsp;<br>Why am I telling you this? Because I get a _lot_ of requests to slice and dice her [Facebook Live](https://www.facebook.com/facebookmedia/solutions/facebook-live) videos into one-minute chunks for posting on  [Instagram](https://www.instagram.com/). Chats like the one at right are not uncommon. :-)<br>&nbsp;<br>Rather than use some time-consuming point-and-click video app I wanted to have a quick command-line way of making her happy in short order.<br>&nbsp;<br>This is how I use a very popular video manipulation tool - ffmpeg - to respond to her requests quickly and easily. I've wrapped ffmpeg in a bit of code to make it painlessly easy to remember and use. Share and enjoy!| ![](./images/whatsappchat.jpg) |

## tl;dr

If you don't want to know what's going on but just want to be able to use my wrapper scripts, all you need is this section. Copy the three code blocks below into the `.bash_profile` in your home directory and start a new terminal window.

| command | explanation |
| :--- | :--- |
| `vseg`&nbsp;`m.mp4`&nbsp;`00:00:00g`&nbsp;`00:01:00` | Cut a one-minute segment from a longer video (named `m.mp4`). The output will be a file called `00_00_00 to  00_01_00.mp4`. |
| `vsplit`&nbsp;`m.mp4g`&nbsp;`60` | Cut a one-minute segment from a longer video. The output will be a file called `00_00_00 to  00_01_00.mp4`. |

## ffmpeg

[ffmpeg](https://www.ffmpeg.org/about.html) is an open-source tool able to manipulate pretty much every video format in existence. It runs on every major platform and a goodly number of minor ones. It was clear this was the way to go.

On my Mac the way to get ffmpeg is to install the [Homebrew package manager](https://brew.sh/) and then `brew install ffmpeg`. Go get a cup of coffee; this'll take a bit as ffmpeg has lots of parts.

## When to cut?

Positions within a movie are specified with _timestamps_ of the format `HH:MM:SS` (hours, minutes, and seconds). ffmpeg will require that we specify a start timestamp and a duration (in seconds) so I use the following function to do the conversion. Note that I don't sanity-check the inputs to be valid such that `99:99:99` will happily be converted but not give you the results you desire. Something for a future day.

```bash
ts2sec() {
	s=(${1//:/ })
	ss=$(((${s[0]}*60*60)+(${s[1]}*60)+${s[2]}))
	echo $ss ;
}
```

## "accurate" cutting of exact frames

Videos are formatted for _in-situ_ and streaming viewing and not for cutting from an arbitrary start and end points. Segments cut directly may not be of the exact length, have a black or jumbled beginning, and other issues.

To accurately cut the exact segment requested we must twice operate on the movie. The first pass will generate key frames all across the segment and store the result in a work-in-progress file.

The second pass will extract the segment, now aided by key frames. The method specified below is the fastest way; there's no re-encoding of video, just a `copy` instruction to the audio and video processors. (Note please that I'm not an ffmpeg expert, and that ffmpeg evolves, so today's "best" command line may be made better tomorrow. Corrections and suggestions gratefully accepted.)

```bash
# -------------------------------------------------------------------------
# Accurately cut a segment from a video with two passes of ffmpeg.
#
# Usage: vseg movie.mp4 start_timestamp end_timestamp
# -------------------------------------------------------------------------
vseg() {
	# Put the supplied parameters into easier-to-read variables.
	SRC="$1" ; START="$2" ; END="$3"

	# Calculate the segment time (in seconds) requested.
	SPAN="$(($( ts2sec "$END" )-$( ts2sec "$START" ) ))"

	# Generate an output filename in macOS-friendly format; replace the
	# colons with underscores and use the same filename  extension as the
	# source video such that an input of "vseg movie.mp4 00:00:00 00:01:00"
	# results in an output filename # of "00_00_00 to 00_01_00.mp4".
	OUT="${START//:/_} to ${END//:/_}.${SRC##*.}"

	# Generate a temporary working file; add the approprite suffix.
	T="$(mktemp video_XXXX)" || exit 1
	WIP="$T.${SRC##*.}"
	mv "$T" "$WIP"

	# Force regeneration of key frames within the desired segment to enable
	# an exact segment cut (with the next command); place into $WIP.
	ffmpeg -i "$SRC" -force_key_frames "$START,$END" -y "$WIP"

	# Cut exactly the segment requested into $OUT.
	ffmpeg -ss "$START" -i "$WIP" -t "$SPAN" -vcodec copy -acodec copy -y "$OUT"

	# Remove the work-in-progress file. List the input and output files.
	rm "$WIP"
	ls -l "$SRC" "$OUT"
}
```

![](./images/00_07_13__00_07_16.png)

## Splitting a video into a series of segments

Now you know how to split a long video into a series of equal smaller segments (albeit with a series of repetitive steps). How can we do it in one fell swoop? I want to be able to type `vsplit really_long_movie.mp4 60` to chop into one-minute (60-second) chunks. Do this with:

```
# -------------------------------------------------------------------------
# vsplit "original.mp4" segment_span_in_seconds # "$(( 1*59 ))"
# -------------------------------------------------------------------------
vsplit() {
	SRC="$1"
	SPAN=$( gdate -d@${2} -u +%H:%M:%S )
	ffmpeg -i "$SRC" -c:v libx264 -crf 22 -map 0 -segment_time $SPAN -g 9 \
		-sc_threshold 0 -force_key_frames "expr:gte(t,n_forced*9)" \
		-reset_timestamps 1 -f segment "segment_%03d.${SRC##*.}"
}
```

We've reached the limits of my expertise with ffmpeg. It's insanely versatile, chock full of features, and is a field of study on its own. Search is your friend :-)