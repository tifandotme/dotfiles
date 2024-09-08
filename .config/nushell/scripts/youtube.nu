alias _yt-dlp = yt-dlp
alias yt-dlp = yt-dlp --extractor-args="youtube:player_client=all" --embed-metadata --embed-chapters --embed-subs --embed-thumbnail --sponsorblock-remove="sponsor,selfpromo,interaction" --progress --quiet --output="%(uploader)s - %(title)s.%(ext)s"

def yd [
  --audio(-a) # Download audio only
  --cwd # Save to current directory (default: ~/Downloads)
  url: string # URL of the thing
] {
  mut download_path = $env.HOME | path join "Downloads"
  if $cwd {
    $download_path = $env.PWD
  }

  print $"Download is starting and will be saved in ($download_path)\n"

  if $audio {
    yt-dlp --paths $download_path -f 140 $url
  } else {
    yt-dlp --paths $download_path --format-sort="res:720,codec:avc:m4a" $url
  }

  if $env.LAST_EXIT_CODE == 0 {
    print "\nDownload successful"
  } else {
    print "\nDownload unsuccessful"
  }
}
