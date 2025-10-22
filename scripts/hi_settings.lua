local SETTINGS_FILE = "hi_settings"

local COLOURS = {
    { text = "Red",    colour = {0.75, 0.25, 0.25, 1.00} },
    { text = "Green",  colour = {0.25, 0.75, 0.25, 1.00} },
    { text = "Blue",   colour = {0.25, 0.25, 0.75, 1.00} },
    { text = "Yellow", colour = {0.75, 0.75, 0.25, 1.00} },
    { text = "Purple", colour = {0.75, 0.25, 0.75, 1.00} },
    { text = "Cian",   colour = {0.25, 0.75, 0.75, 1.00} },
    { text = "Grey",   colour = {0.75, 0.75, 0.75, 1.00} },
}

local DEFAULT_SETTINGS = {
    -- hp number, hp bar, damage number
    opacities = {1, 1, 1},
    -- neutral, friend, hostile, player
    colours = {7, 2, 1, 5},
    -- current player, other players, bosses, structures, other entities, all other normally hidden entities (walls, boats), enemies
    visibilities = {true, true, true, true, true, false, true},
}

local HiSettings = {
    data = DEFAULT_SETTINGS,
    cached_hp_widgets = {},
    cached_hp_widgets_num = 0,
}

function HiSettings:GetHealthNumberOpacity()
    return self.data.opacities[1]
end

function HiSettings:GetOpacity(type)
    local verified_type = math.clamp(type, 1, #self.data.opacities)
    return self.data.opacities[verified_type]
end

function HiSettings:SetOpacity(type, opacity)
    local verified_type = math.clamp(type, 1, #self.data.opacities)
    local verified_opacity = math.clamp(opacity, 0, 1)
    self.data.opacities[verified_type] = verified_opacity
end

function HiSettings:GetHealthBarOpacity()
    return self.data.opacities[2]
end

function HiSettings:GetDamageNumberOpacity()
    return self.data.opacities[3]
end

function HiSettings:GetAllColours()
    return COLOURS
end

function HiSettings:SetColourIndex(type, index)
    local verified_type = math.clamp(type, 1, #self.data.colours)
    local verified_index = math.clamp(index, 1, #COLOURS)
    self.data.colours[verified_type] = verified_index
end

function HiSettings:GetColourIndex(type)
    local verified_type = math.clamp(type, 1, #self.data.colours)
    return self.data.colours[verified_type]
end

function HiSettings:GetColour(type)
    local verified_type = math.clamp(type, 1, #self.data.colours)
    return COLOURS[self.data.colours[verified_type]].colour
end

function HiSettings:SetVisibility(type, visibility)
    local verified_type = math.clamp(type, 1, #self.data.visibilities)
    self.data.visibilities[verified_type] = visibility
end

function HiSettings:GetVisibility(type)
    local verified_type = math.clamp(type, 1, #self.data.visibilities)
    return self.data.visibilities[verified_type]
end

function HiSettings:UpdateWidgets()
    for _, widget in pairs(self.cached_hp_widgets) do
        widget:ApplySettings()
    end
end

function HiSettings:Save()
    TheSim:SetPersistentString(SETTINGS_FILE, json.encode(self.data), true)
    self:UpdateWidgets()
end

function HiSettings:Load()
    TheSim:GetPersistentString(SETTINGS_FILE, function(success, data)
        if data == nil or data == "" then
            return
        end
        local decoded_data = json.decode(data)
        if decoded_data.opacities ~= nil then
            for i = 1, math.min(#self.data.opacities, #decoded_data.opacities) do
                self.data.opacities[i] = decoded_data.opacities[i]
            end
        end
        if decoded_data.colours ~= nil then
            for i = 1, math.min(#self.data.colours, #decoded_data.colours) do
                self.data.colours[i] = decoded_data.colours[i]
            end
        end
        if decoded_data.visibilities ~= nil then
            for i = 1, math.min(#self.data.visibilities, #decoded_data.visibilities) do
                self.data.visibilities[i] = decoded_data.visibilities[i]
            end
        end
    end)
    self:UpdateWidgets()
end

return HiSettings
