#
# Sync MCP server configs from mcpo/config.json to Zed and OpenCode settings,
# preserving enabled status and formatting with prettier for consistency.
#

let MCP_CONFIG_PATH = ($env.XDG_CONFIG_HOME | path join mcpo config.json)
let ZED_SETTINGS_PATH = ($env.XDG_CONFIG_HOME | path join zed settings.json)
let OPENCODE_CONFIG_PATH = ($env.XDG_CONFIG_HOME | path join opencode opencode.json)

# Transform servers for Zed format (adds "source": "custom")
def transform_for_zed [servers] {
  $servers
  | items {|server_name server_data|
    let updated_data = $server_data | insert source "custom"
    {($server_name): $updated_data}
  }
  | reduce -f {} {|acc item| $acc | merge $item }
}

# Transform servers for OpenCode format
def transform_for_opencode [servers] {
  $servers
  | items {|server_name server_data|

    
    # Convert command and args to command array
    let command_array = if ($server_data | get -o args | is-empty) {
      [$server_data.command]
    } else {
      [$server_data.command] ++ $server_data.args
    }

    # Use env object directly (already in correct format)
    let environment = if ($server_data | get -o env | is-empty) {
      {}
    } else {
      $server_data.env
    }

    let opencode_data = {
      type: "local"
      command: $command_array
      enabled: $server_data.enabled
      environment: $environment
    }

    {($server_name): $opencode_data}
  }
  | reduce -f {} {|acc item| $acc | merge $item }
}

def main [] {
  let mcp_servers = open $MCP_CONFIG_PATH | get mcpServers

  # Transform servers for Zed
  let zed_servers = transform_for_zed $mcp_servers

  # Transform servers for OpenCode
  let opencode_servers = transform_for_opencode $mcp_servers

  # Update Zed settings
  let zed_settings = open $ZED_SETTINGS_PATH
  let updated_zed_settings = $zed_settings | update context_servers $zed_servers
  $updated_zed_settings | to json --indent 2 | save --force $ZED_SETTINGS_PATH
  run-external "bunx" "prettier" "--write" $ZED_SETTINGS_PATH

  # Update OpenCode config
  let opencode_config = open $OPENCODE_CONFIG_PATH
  let updated_opencode_config = $opencode_config | upsert mcp $opencode_servers
  $updated_opencode_config | to json --indent 2 | save --force $OPENCODE_CONFIG_PATH
  run-external "bunx" "prettier" "--write" $OPENCODE_CONFIG_PATH

  print $"Successfully updated ($ZED_SETTINGS_PATH) and ($OPENCODE_CONFIG_PATH) with servers from ($MCP_CONFIG_PATH)!"
}
