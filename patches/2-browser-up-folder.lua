local BD = require("ui/bidi")
local FileChooser = require("ui/widget/filechooser")
local logger = require("logger")

local Icon = {
    home = "home",
    up = BD.mirroredUILayout() and "back.top.rtl" or "back.top",
}

function Setting(name, default)
    self = {}
    self.get = function() return G_reader_settings:readSetting(name, default) end
    self.toggle = function() G_reader_settings:toggle(name) end
    return self
end

local HideEmpty = Setting("filemanager_hide_empty_folder", false)
local HideUp = Setting("filemanager_hide_up_folder", true)

function FileChooser:_changeLeftIcon(icon, func)
    local titlebar = self.title_bar
    titlebar.left_icon = icon
    titlebar.left_icon_tap_callback = func
    if titlebar.left_button then
        titlebar.left_button:setIcon(icon)
        titlebar.left_button.callback = func
    end
end

function FileChooser:_isEmptyDir(item)
    if item.attr and item.attr.mode == "directory" then
        local sub_dirs, dir_files = self:getList(item.path, {})
        local empty = #dir_files == 0
        if empty then -- recurse in sub dirs
            for _, sub_dir in ipairs(sub_dirs) do
                if not self:_isEmptyDir(sub_dir) then
                    empty = false
                    break
                end
            end
        end
        return empty
    end
end

local orig_FileChooser_genItemTable = FileChooser.genItemTable

function FileChooser:genItemTable(dirs, files, path)
    local item_table = orig_FileChooser_genItemTable(self, dirs, files, path)
    if self._dummy or self.name ~= "filemanager" then return item_table end

    local items = {}
    local is_sub_folder = false
    for _, item in ipairs(item_table) do
        if item.path:find("\u{e257}/") then
            table.insert(items, item) -- fix https://github.com/sebdelsol/KOReader.patches/issues/23
        elseif (item.is_go_up or item.text:find("\u{2B06} ..")) and HideUp.get() then
            is_sub_folder = true
        elseif not (HideEmpty.get() and self:_isEmptyDir(item)) then
            table.insert(items, item)
        end
    end

    if HideEmpty.get() and #items == 0 then
        self:onFolderUp()
        return
    end

    self._left_tap_callback = self._left_tap_callback or self.title_bar.left_icon_tap_callback
    if is_sub_folder then
        self:_changeLeftIcon(Icon.up, function() self:onFolderUp() end)
    else
        self:_changeLeftIcon(Icon.home, self._left_tap_callback)
    end
    return items
end

-- Patch filemanager menu
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local _ = require("gettext")

local orig_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable

function FileManagerMenu:setUpdateItemTable()
    local function patch(entry, text, setting)
        local settings_order = FileManagerMenuOrder.filemanager_settings
        table.insert(settings_order, #settings_order - 1, entry)
        self.menu_items[entry] = {
            text = text,
            checked_func = setting.get,
            callback = function(touchmenu_instance)
                setting.toggle()
                self.ui.file_chooser:refreshPath()
            end,
        }
    end

    patch("hide_empty_folder", _("Hide empty folders"), HideEmpty)
    patch("hide_up_folder", _("Hide up folders"), HideUp)
    orig_FileManagerMenu_setUpdateItemTable(self)
end
