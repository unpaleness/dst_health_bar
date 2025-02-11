name = "Health indicators"
description = "Adds health widgets to all entities that have health"
author = "unpaleness"
version = "0.0.2"

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

-- icon_atlas = "icon.xml"
-- icon = "icon.tex"

configuration_options =
{
	-- This is an "empty" setting, which functions as a headline for the coming settings.
	{
		name 	= "",
		label 	= "General Settings",
		options =	{
						{description = "", data = 0},
					},
		default = 0,
	},
	{
		name = "show_hp",
		label = "Show HP",
		options =	{
						{description = "Yes", data = true},
						{description = "No", data = false},
					},
		default = true,
	},
}