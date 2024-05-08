alias _yt-dlp = ^yt-dlp --extractor-args="youtube:player_client=web" --embed-metadata --embed-chapters --embed-subs --embed-thumbnail --sponsorblock-remove="sponsor,selfpromo,interaction" --progress --quiet --paths="~/videos/youtube" --output="%(uploader)s - %(title)s.%(ext)s"

export def yd [
  --audio(-a) # Download audio only
  url: string # URL of the thing
] {
  if $audio {
    _yt-dlp -f 140 $url
  } else {
    _yt-dlp --format-sort="res:720,codec:avc:m4a" $url
  }

  if $env.LAST_EXIT_CODE == 0 {
    print "Saved in ~/videos/youtube"
  }
}
