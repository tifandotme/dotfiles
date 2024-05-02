# additional config is stored at ~/.config/yt-dlp/config

command -v yt-dlp &> /dev/null || return

yd() {
  if [[ "$1" == "" ]]; then
    echo "Usage: yd \"[url]\""
    return
  fi

  echo "Choose a video resolution, or audio only:"
  echo "1. 720p"
  echo "2. 1080p"
  echo "3. Audio only"
  echo "Enter your choice (1-3): "
  read -r choice

  case "$choice" in
    1) yt-dlp --format-sort "res:720,codec:avc:m4a" "$1" ;;
    2) yt-dlp --format-sort "res:1080,codec:avc:m4a" "$1" ;;
    3) yt-dlp -f 140 "$1" ;;
    *) echo "Invalid choice." ;;
  esac

  echo "\nDownloaded and stored at ~/Videos/YouTube"
}
