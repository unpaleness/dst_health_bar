local SETTINGS_FILE = "hi_settings"

local DEFAULT_SETTINGS = {
    hp_number_opacity = 1,
    hp_bar_opacity = 1,
    damage_number_opacity = 1
}

local HiSettings = {
    data = DEFAULT_SETTINGS,
    cached_hp_widgets = {},
}

function HiSettings:UpdateWidgets()
    for _, widget in pairs(self.cached_hp_widgets) do
        widget:SetHpBarOpacity(self.data.hp_bar_opacity)
        widget:SetHpNumberOpacity(self.data.hp_number_opacity)
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
        if decoded_data.hp_number_opacity ~= nil then
            self.data.hp_number_opacity = decoded_data.hp_number_opacity
        end
        if decoded_data.hp_bar_opacity ~= nil then
            self.data.hp_bar_opacity = decoded_data.hp_bar_opacity
        end
        if decoded_data.damage_number_opacity ~= nil then
            self.data.damage_number_opacity = decoded_data.damage_number_opacity
        end
    end)
    self:UpdateWidgets()
end

return HiSettings
