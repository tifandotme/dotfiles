export def "stop-all" [--stop-colima (-c)] {
  docker stop ...(docker ps -aq | lines | str trim)
  if ($stop_colima) {
    colima stop
  }
}

export def open-firecrawl [] {
  let absolute_path = $env.HOME | path join personal firecrawl
  let tab_name = "firecrawl"

  let existing_tabs = zellij action query-tab-names | split row "\n"
  if $tab_name in $existing_tabs {
    zellij action go-to-tab-name $tab_name
    return
  }

  let cmd = "if (colima status --json | from json | is-empty) { colima start }; if not (docker compose ps | str contains 'Up') { docker compose up -d }; lazydocker"

  zellij action new-tab --name $tab_name
  zellij run --close-on-exit --cwd $absolute_path -- nu -c $cmd
  zellij action focus-previous-pane; zellij action close-pane
}

export def open-memory-graph [] {
  if (which dot | is-empty) {
    print "Graphviz not installed. Install with: brew install graphviz"
    return
  }

  let json = (docker run --rm -v my-memory:/data alpine cat /data/memory.json)
  let data = $json | lines | where {|line| $line != "" } | each {|line| $line | from json }

  let entities = $data | where type == "entity" | each {|e|
      let obs = $e.observations | each {|o| $o | str replace -r ": *" " " } | each {|o| $"- ($o)" } | str join "\n"
      $"\"($e.name)\" [label=\"($e.entityType)\n($obs)\" shape=box];"
    }

  let relations = $data | where type == "relation" | each {|r|
      $"\"($r.from)\" -> \"($r.to)\" [label=\"($r.relationType)\"];"
    }

  let dot = $"digraph G {\n($entities | append $relations | str join "\n")\n}"
  $dot | dot -Tpng -o /tmp/graph.png
  ^open /tmp/graph.png
}
