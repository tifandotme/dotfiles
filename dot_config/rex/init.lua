-- Rex GUI settings (font, themes, shader, layout) live in the app, not here.
-- Reload after editing: rex config reload

-- Cmd+Enter sends Ctrl+Enter so Amp queues the message (prompt.queue in amp.keymap).
rex.bind("cmd+enter", "pane.send_key", { key = "ctrl+enter" })

rex.unbind("cmd+k", "session.switch")
rex.unbind("shift+cmd+p", "client.palette.toggle")
rex.unbind("cmd+p", "pane.go_to")
rex.unbind("alt+cmd+left", "pane.focus.left")
rex.unbind("alt+cmd+right", "pane.focus.right")
rex.unbind("alt+cmd+up", "pane.focus.up")
rex.unbind("alt+cmd+down", "pane.focus.down")
rex.unbind("cmd+]", "pane.focus_next")
rex.unbind("cmd+[", "pane.focus_previous")
rex.unbind("shift+cmd+n", "session.new")
rex.unbind("alt+shift+cmd+n", "session.new.on_host")

rex.bind("cmd+k", "client.palette.toggle")
rex.bind("cmd+p", "session.switch")
rex.bind("alt+h", "pane.focus.left")
rex.bind("alt+l", "pane.focus.right")
rex.bind("alt+k", "pane.focus.up")
rex.bind("alt+j", "pane.focus.down")
rex.bind("cmd+]", "session.next")
rex.bind("cmd+[", "session.previous")
rex.bind("shift+cmd+t", "session.new")
rex.bind("cmd+n", "client.window.new")
