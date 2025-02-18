local SETTINGS_FILE = "hi_settings"

local DEFAULT_SETTINGS = {
    hp_bar_opacity = 1
}

local HiSettings = {
    data = DEFAULT_SETTINGS,
    cached_hp_widgets = {},
}

function HiSettings:UpdateWidgets()
    for _, widget in pairs(self.cached_hp_widgets) do
        widget:SetOpacity(self.data.hp_bar_opacity)
    end
end

function HiSettings:Save()
    TheSim:SetPersistentString(SETTINGS_FILE, json.encode(self.data), false)
    self:UpdateWidgets()
end

function HiSettings:Load()
    TheSim:GetPersistentString(SETTINGS_FILE, function(success, data)
        if data == nil or data == "" then
            return
        end
        local decoded_data = json.decode(data)
        if decoded_data.hp_bar_opacity ~= nil then
            self.data.hp_bar_opacity = decoded_data.hp_bar_opacity
        end
    end)
    self:UpdateWidgets()
end

return HiSettings
