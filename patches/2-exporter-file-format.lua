local userpatch = require("userpatch")
local util = require("util")
userpatch.registerPatchPluginFunc("exporter", function(plugin)
    local init_orig = plugin.init
    plugin.init = function(self)
        init_orig(self)
        for _, v in pairs(self.targets) do
            v.getFilePath = function(v_self, t)
                if v_self.is_remote then return end
                local plugin_settings = G_reader_settings:readSetting("exporter") or {}
                local clipping_dir = plugin_settings.clipping_dir or v_self.clipping_dir
                local filename
                if #t == 1 then
                    if plugin_settings.clipping_dir_book then
                        clipping_dir = util.splitFilePathName(t[1].file):sub(1, -2)
                    end
                    -- single book export filename
                    filename = string.format("%s-%s-%s.%s", t[1].author, t[1].title, os.date("%Y%m%d-%H%M%S"), v_self.extension)
                    filename = string.gsub(filename, " ", "_")
                else
                    local title = v_self.all_books_title or "All-Books"
                    filename = string.format("%s-%s.%s", title, os.date("%Y%m%d-%H%M%S"), v_self.extension)
                end
                return clipping_dir .. "/" .. util.getSafeFilename(filename)
            end
        end
    end
end)
