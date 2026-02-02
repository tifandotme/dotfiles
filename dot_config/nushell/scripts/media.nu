alias _yt-dlp = yt-dlp
alias yt-dlp = yt-dlp --extractor-args="youtube:player_client=all" --embed-metadata --embed-chapters --embed-subs --embed-thumbnail --sponsorblock-remove="sponsor,selfpromo,interaction" --progress --quiet --output="%(uploader)s - %(title)s.%(ext)s"

export def --wrapped "youtube-download" [
  --audio (-a)
  --cwd
  url: string
  ...rest
] {
  mut download_path = $env.HOME | path join "Downloads"
  if $cwd {
    $download_path = $env.PWD
  }

  print $"Download starting, saving to ($download_path)\n"

  mut cmd = [yt-dlp --paths $download_path]

  if $audio {
    $cmd = ($cmd | append [-f 140])
  } else {
    $cmd = ($cmd | append [--format-sort="res:720,codec:avc:m4a"])
  }

  $cmd = ($cmd | append $rest)
  $cmd = ($cmd | append $url)

  ^($cmd.0) ...($cmd | skip 1)

  if $env.LAST_EXIT_CODE == 0 {
    print "\nDownload successful"
  } else {
    print "\nDownload failed"
  }
}

export def open-book [] {
  try {
    let books_dir = $"($env.HOME)/personal/books/"
    let books = _ls ...(glob $"($books_dir)**/*.{pdf,epub}") | get name
    let chosen = $books | str join "\n" | str replace --all $books_dir '' | str join "\n" | fzf
    ^open $"($books_dir)($chosen)"
  } catch {
    print "No books found."
  }
}
