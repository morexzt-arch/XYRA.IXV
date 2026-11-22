
-- ============================================================================
-- XYRA.IXV - NATIVE GROWLAUNCHER MENU BUILDER
-- Based on UI 1 Native Launcher
-- Version: 1.0.1
-- ============================================================================

local NativeMenuBuilder = {}
NativeMenuBuilder.__index = NativeMenuBuilder

-- JSON ENCODER

local function safeJsonEncode(val)
    if jsonEncode then
        return jsonEncode(val)
    end

    if json and json.encode then
        return json.encode(val)
    end

    local t = type(val)

    if t == "string" then
        return '"' .. val:gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\r', '\\r') .. '"'

    elseif t == "number" or t == "boolean" then
        return tostring(val)

    elseif t == "table" then
        local isArr = (#val > 0)
        local parts = {}

        if isArr then
            for _, v in ipairs(val) do
                table.insert(parts, safeJsonEncode(v))
            end

            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                table.insert(
                    parts,
                    safeJsonEncode(tostring(k)) ..
                    ":" .. safeJsonEncode(v)
                )
            end

            return "{" .. table.concat(parts, ",") .. "}"
        end
    end

    return "null"
end

-- CREATE MENU

function NativeMenuBuilder.new(subName, iconName)
    local self = setmetatable({}, NativeMenuBuilder)

    self.sub_name = subName or "Menu"
    self.icon = iconName or "Settings"
    self.menu = {}

    return self
end

-- LABEL APP

function NativeMenuBuilder:addLabelApp(text, icon)
    table.insert(self.menu, {
        type = "labelapp",
        text = tostring(text or ""),
        icon = icon or "Storefront"
    })

    return self
end

-- LABEL

function NativeMenuBuilder:addLabel(text)
    table.insert(self.menu, {
        type = "label",
        text = tostring(text or "")
    })

    return self
end

-- DIVIDER

function NativeMenuBuilder:addDivider()
    table.insert(self.menu, {
        type = "divider"
    })

    return self
end

-- TOGGLE

function NativeMenuBuilder:addToggle(text, defaultVal, alias, autoSave)
    table.insert(self.menu, {
        type = "toggle",
        text = tostring(text or ""),
        default = (defaultVal == true),
        alias = tostring(alias or ""),
        autosave = (autoSave == true)
    })

    return self
end

-- TOGGLE BUTTON

function NativeMenuBuilder:addToggleButton(text, defaultVal, alias)
    table.insert(self.menu, {
        type = "toggle_button",
        text = tostring(text or ""),
        default = (defaultVal == true),
        alias = tostring(alias or "")
    })

    return self
end

-- BUTTON

function NativeMenuBuilder:addButton(text, alias)
    table.insert(self.menu, {
        type = "button",
        text = tostring(text or ""),
        alias = tostring(alias or "")
    })

    return self
end

-- STRING INPUT

function NativeMenuBuilder:addInputString(
    text, defaultVal, label, placeholder, icon, alias
)
    table.insert(self.menu, {
        type = "input_string",
        text = tostring(text or ""),
        default = tostring(defaultVal or ""),
        label = tostring(label or "Text"),
        placeholder = tostring(placeholder or ""),
        icon = icon or "Public",
        alias = tostring(alias or "")
    })

    return self
end

-- INTEGER INPUT

function NativeMenuBuilder:addInputInt(
    text, defaultVal, label, placeholder, icon, alias
)
    table.insert(self.menu, {
        type = "input_int",
        text = tostring(text or ""),
        default = tostring(defaultVal or "0"),
        label = tostring(label or "Angka"),
        placeholder = tostring(placeholder or "0"),
        icon = icon or "Numbers",
        alias = tostring(alias or "")
    })

    return self
end

-- SLIDER

function NativeMenuBuilder:addSlider(
    text, minVal, maxVal, defaultVal, stepVal, useDot, alias
)
    table.insert(self.menu, {
        type = "slider",
        text = tostring(text or ""),
        min = tonumber(minVal) or 0,
        max = tonumber(maxVal) or 100,
        default = tonumber(defaultVal) or tonumber(minVal) or 0,
        step = tonumber(stepVal) or 1,
        usedot = (useDot == true),
        alias = tostring(alias or "")
    })

    return self
end

-- TOOLTIP

function NativeMenuBuilder:addTooltip(
    text, supportText, icon, background
)
    table.insert(self.menu, {
        type = "tooltip",
        text = tostring(text or ""),
        support_text = tostring(supportText or ""),
        icon = icon or "Info",
        background = (background == true)
    })

    return self
end

-- ITEM PICKER

function NativeMenuBuilder:addItemPicker(text, item, defaultVal, alias)
    table.insert(self.menu, {
        type = "item_picker",
        text = tostring(text or ""),
        item = item or "Blank",
        default = tostring(defaultVal or "0"),
        alias = tostring(alias or "")
    })

    return self
end

-- DISPLAY LIST

function NativeMenuBuilder:addDisplayList(text, defaultVal, alias)
    table.insert(self.menu, {
        type = "display_list",
        text = tostring(text or ""),
        default = tostring(defaultVal or "Default"),
        alias = tostring(alias or "")
    })

    return self
end

-- EXPANDABLE TOGGLE

function NativeMenuBuilder:addExpandableToggle(
    text, defaultVal, alias, alwaysExpand, background
)
    local obj = {
        type = "expandable_toggle",
        text = tostring(text or ""),
        default = (defaultVal == true),
        alias = tostring(alias or ""),
        always_expand = (alwaysExpand == true),
        background = (background == true),
        list_child = {}
    }

    table.insert(self.menu, obj)

    return obj
end

-- CHILD BUTTON

function NativeMenuBuilder:addChildButton(cardObj, text, alias)
    if cardObj and type(cardObj.list_child) == "table" then
        table.insert(cardObj.list_child, {
            type = "button",
            text = tostring(text or ""),
            alias = tostring(alias or "")
        })
    end

    return self
end

-- CHILD TOGGLE

function NativeMenuBuilder:addChildToggle(
    cardObj, text, defaultVal, alias, autoSave
)
    if cardObj and type(cardObj.list_child) == "table" then
        table.insert(cardObj.list_child, {
            type = "toggle",
            text = tostring(text or ""),
            default = (defaultVal == true),
            alias = tostring(alias or ""),
            autosave = (autoSave == true)
        })
    end

    return self
end

-- GENERATE JSON

function NativeMenuBuilder:generateJSON()
    return safeJsonEncode({
        sub_name = self.sub_name,
        icon = self.icon,
        menu = self.menu
    })
end

-- ============================================================================
-- GLOBAL REGISTRY HELPERS
-- ============================================================================

-- REGISTER CATEGORY

function NativeMenuBuilder.registerCategory(categoryName, iconName)
    if type(addCategory) == "function" then
        return pcall(
            addCategory,
            tostring(categoryName),
            iconName or "Folder"
        )
    end

    return false
end

-- ADD MENU TO CATEGORY
-- Correct parameter order: JSON first, category second.

function NativeMenuBuilder.addMenuToCategory(categoryName, menuBuilderObj)
    if type(addIntoModule) == "function"
        and menuBuilderObj
        and type(menuBuilderObj.generateJSON) == "function"
    then
        local jsonStr = menuBuilderObj:generateJSON()

        return pcall(
            addIntoModule,
            jsonStr,
            tostring(categoryName)
        )
    end

    return false
end

-- EDIT TOGGLE

function NativeMenuBuilder.setToggle(alias, boolVal)
    if type(editToggle) == "function" then
        return pcall(editToggle, alias, boolVal == true)
    end

    return false
end

-- EDIT DISPLAY LIST

function NativeMenuBuilder.setDisplayList(alias, textVal)
    if type(editDisplayList) == "function" then
        return pcall(
            editDisplayList,
            alias,
            tostring(textVal)
        )
    end

    return false
end

-- RETURN MODULE

return NativeMenuBuilder
