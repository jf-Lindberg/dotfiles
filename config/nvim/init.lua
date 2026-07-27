-- Entry point. Order matters: options and leader key must be set before
-- lazy.nvim loads any plugin, since plugin keymaps are defined against <leader>.

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
