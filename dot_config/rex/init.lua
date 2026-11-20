-- Rex GUI settings (font, themes, shader, layout) live in the app, not here.
-- Reload after editing: rex config reload

-- Cmd+Enter sends Ctrl+Enter so Amp queues the message (prompt.queue in amp.keymap).
rex.bind("cmd+enter", "pane.send_key", { key = "ctrl+enter" })
