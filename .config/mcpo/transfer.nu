#
# Update Zed Settings from MCP Config
#
# This script reads server configurations from a source JSON file (mcpo/config.json),
# modifies them, and updates a destination JSON file (zed/settings.json).
#
# Key operations:
# 1. Reads the `mcpServers` object from the source file.
# 2. Adds a `"source": "custom"` key-value pair to each server entry.
# 3. Overwrites the `context_servers` object in the destination file with the modified data.
#

let MCP_CONFIG_PATH = ($env.XDG_CONFIG_HOME | path join mcpo config.json)
let ZED_SETTINGS_PATH = ($env.XDG_CONFIG_HOME | path join zed settings.json)

def main [] {
  let mcp_servers = open $MCP_CONFIG_PATH | get mcpServers

  # Add the "source": "custom" field to each server.
  let updated_servers = $mcp_servers
  | columns
  | each {|server_name|
    let server_data = $mcp_servers | get $server_name
    let updated_data = $server_data | insert source "custom"
    {($server_name): $updated_data}
  }
  | reduce -f {} {|acc item| $acc | merge $item } # Merge the list of records back into a single record.

  let zed_settings = open $ZED_SETTINGS_PATH

  let updated_zed_settings = $zed_settings | update context_servers $updated_servers

  $updated_zed_settings | to json --indent 2 | save --force $ZED_SETTINGS_PATH

  print $"Successfully updated ($ZED_SETTINGS_PATH) with servers from ($MCP_CONFIG_PATH)!"
}
