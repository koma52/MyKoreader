local VirtualKeyboard = require("ui/widget/virtualkeyboard")

local logger = require("logger")

local orig_addKeys = VirtualKeyboard.addKeys
VirtualKeyboard.addKeys = function(self)
    orig_addKeys(self)
    for _, j in ipairs(self[1][1][1][1]) do
        for _, i in ipairs(j) do
            if i.label ~= "" then
                i.hold_callback = function() logger.dbg("disabled keyboard hold") end
            end
        end
    end
end

