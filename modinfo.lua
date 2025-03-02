name = "Health indicators"
description = [[
Features:
- health bars with dynamic color coding
- damage indicators
]]
author = "unpaleness"
version = "0.0.11"

steam_description = [[
[b]A very base health and damage indicators[/b]

[h3]Features:[/h3]
[list]
[*]health bars are dynamically colored based on hostility of target:
[list]
[*]purple - player
[*]green - allies
[*]grey - neutral toward player (at the moment)
[*]red - hostile
[/list]
[*]health bars are scaled based on max hp of target
[*]damage indicators emit on HP change (red - damage, green - heal)
[*]works on both local games and dedicated servers
[*]settings (only hp bar opacity for now)
[/list]

[h3]Notes:[/h3]
[list]
[*]DST only
[/list]

[h3]Plans:[/h3]
[list]
[*]add some stuff on hp bars to improve feedback (animations of hp lost/obtained)
[*]make damage indicators color based on damage type (like in RPGs)
[*]add more customization for clients
[/list]
]]

forumthread = ""

api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
hamlet_compatible = false
dst_compatible = true

all_clients_require_mod = true
client_only_mod = false

priority = 0

icon_atlas = "images/icon.xml"
icon = "icon.tex"

configuration_options =
{
	-- {
	-- 	name = "show_hp",
	-- 	label = "Show HP",
	-- 	options =	{
	-- 					{description = "Yes", data = true},
	-- 					{description = "No", data = false},
	-- 				},
	-- 	default = true,
	-- },
}