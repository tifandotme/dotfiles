on open fileItems
	if (count of fileItems) is 0 then return

	set homeDirectory to POSIX path of (path to home folder)
	set toolEnvironment to "PATH=" & quoted form of (homeDirectory & ".local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin") & "; export PATH; "
	set firstPath to POSIX path of (item 1 of fileItems)
	set workingDirectory to do shell script "/usr/bin/dirname " & quoted form of firstPath
	set tabLabel to do shell script "/usr/bin/basename " & quoted form of firstPath
	set tabJSON to do shell script toolEnvironment & "herdr tab create --cwd " & quoted form of workingDirectory & " --label " & quoted form of (tabLabel & " (nvim)") & " --focus"
	set paneID to do shell script toolEnvironment & "printf %s " & quoted form of tabJSON & " | jq -r '.result.root_pane.pane_id'"
	set nvimCommand to "nvim"

	repeat with fileItem in fileItems
		set nvimCommand to nvimCommand & " " & quoted form of (POSIX path of fileItem)
	end repeat

	do shell script toolEnvironment & "herdr pane run " & quoted form of paneID & " " & quoted form of nvimCommand
	tell application "Ghostty" to activate
end open

on run
	return
end run
