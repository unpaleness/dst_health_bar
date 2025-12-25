require("translator")

local TRANSLATIONS = {
    hiButtonSettings = {
        en = "HI Settings",
        ru = "HI Настройки",
    },
    hiButtonClose = {
        en = "Close",
        ru = "Закрыть",
    },
    hiCheckboxOtherMaxHealth = {
        en = "Show max health",
        ru = "Показывать макс. здоровье",
    },
    hiCheckboxOtherOnlyInBattle = {
        en = "Show hp only in battle",
        ru = "Прятать здоровье вне боя",
    },
    hiCheckboxOtherOutOfBattleAllies = {
        en = "Except for allies",
        ru = "За исключением союзников",
    },
    hiCheckboxOtherOutOfBattlePlayers = {
        en = "Except for players",
        ru = "За исключением игроков",
    },
    hiCheckboxOtherShowOnMouseOver = {
        en = "Show hp on mouse over",
        ru = "Показывать при наведении мыши",
    },
    hiCheckboxVisibilityAllies = {
        en = "Allies",
        ru = "Союзники",
    },
    hiCheckboxVisibilityBosses = {
        en = "Bosses",
        ru = "Боссы",
    },
    hiCheckboxVisibilityEnemies = {
        en = "Enemies",
        ru = "Враги",
    },
    hiCheckboxVisibilityMe = {
        en = "Me",
        ru = "Я",
    },
    hiCheckboxVisibilityOtherEntities = {
        en = "Other entities",
        ru = "Другие сущности",
    },
    hiCheckboxVisibilityOtherPlayers = {
        en = "Other players",
        ru = "Другие игроки",
    },
    hiCheckboxVisibilityOtherStructures = {
        en = "Walls, boats, bumpers",
        ru = "Стены, лодки, бамперы",
    },
    hiCheckboxVisibilityStructures = {
        en = "Structures",
        ru = "Постройки",
    },
    hiColourRed = {
        en = "Red",
        ru = "Красный",
    },
    hiColourGreen = {
        en = "Green",
        ru = "Зелёный",
    },
    hiColourBlue = {
        en = "Blue",
        ru = "Синий",
    },
    hiColourYellow = {
        en = "Yellow",
        ru = "Жёлтый",
    },
    hiColourPurple = {
        en = "Purple",
        ru = "Фиолетовый",
    },
    hiColourCian = {
        en = "Cian",
        ru = "Лазурный",
    },
    hiColourGrey = {
        en = "Grey",
        ru = "Серый",
    },
    hiTitleMeasurementMillisecond = {
        en = "ms",
        ru = "мс",
    },
    hiTitleMeasurementSecond = {
        en = "s",
        ru = "с",
    },
    hiSpinnerColourAllies = {
        en = "Allies",
        ru = "Союзники",
    },
    hiSpinnerColourEnemies = {
        en = "Enemies",
        ru = "Враги",
    },
    hiSpinnerColourNeutral = {
        en = "Neutral",
        ru = "Нейтральные",
    },
    hiSpinnerColourPlayer = {
        en = "Players",
        ru = "Игроки",
    },
    hiSpinnerOpacityHpValue = {
        en = "Health number",
        ru = "Значение здоровья",
    },
    hiSpinnerOpacityHpBar = {
        en = "Health bar",
        ru = "Индикатор здоровья",
    },
    hiSpinnerOpacityDamageValue = {
        en = "Damage number",
        ru = "Значение урона",
    },
    hiSpinnerOtherFadeAnim = {
        en = "Fade in/out transition",
        ru = "Переход из/в прозрачность",
    },
    hiSpinnerOtherHideHpOutOfCombat = {
        en = "Hide hp after last attack",
        ru = "Прятать индикатор после боя",
    },
    hiSpinnerOtherScale = {
        en = "Scale of all widgets",
        ru = "Масштаб всех виджетов",
    },
    hiTitleOpacity = {
        en = "Opacity",
        ru = "Непрозрачность",
    },
    hiTitleColour = {
        en = "Colour",
        ru = "Цвет",
    },
    hiTitleVisibility = {
        en = "Visibility",
        ru = "Видимость",
    },
    hiTitleOther = {
        en = "Other",
        ru = "Разное",
    },
}

local SUPPORTED_LANGUAGES = {
    en = true,
    ru = true,
}

local FALLBACK_LANGUAGE = "en"

local function GetLanguage()
    local lang = LanguageTranslator and LanguageTranslator.defaultlang or FALLBACK_LANGUAGE
    local isLanguageSupported = SUPPORTED_LANGUAGES[lang]
    lang = (isLanguageSupported ~= nil and isLanguageSupported) and lang or FALLBACK_LANGUAGE
    return lang
end

local HiLocalization = {
    data = TRANSLATIONS,
    lang = GetLanguage()
}

function HiLocalization:Get(key)
    local translations = self.data[key]
    if translations == nil then
        print("HiLocalization:Get: invalid key", key)
        return "<" .. key .. ">"
    end
    local value = translations[self.lang]
    if value == nil then
        print("HiLocalization:Get: missing translation of key", key, "for language", self.lang)
        return "<" .. key .. ">"
    end
    return value
end

return HiLocalization
