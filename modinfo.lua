name = "Health indicators"
description = [[
Version: 0.0.22
Features:
- health bars with dynamic colour coding
- damage indicators
- in-game settings
]]
author = "unpaleness"
version = "0.0.22"

steam_description = [[
[b]A very base health and damage indicators[/b]

[h3]Features:[/h3]
[list]
[*]health bars are dynamically coloured based on hostility of target (players/allies/neutrals/hostiles)
[*]health bars are scaled based on max hp of target
[*]damage indicators emit on HP change (red - damage, green - heal)
[*]works on both local games and dedicated servers
[*]settings (opacity and colours)
[/list]

[h3]Notes:[/h3]
[list]
[*]DST only
[/list]

[h3]Plans:[/h3]
[list]
[*]add some stuff on hp bars to improve feedback (animations of hp lost/obtained)
[*]make damage indicators colour based on damage type (like in RPGs)
[*]add more customization for clients
[/list]

Feel free to express any feedback. I keep source open here: https://github.com/unpaleness/dst_health_bar
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