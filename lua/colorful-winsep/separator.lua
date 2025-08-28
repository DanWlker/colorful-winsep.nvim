local api = vim.api
local uv = vim.uv

---@class Separator
---@field start_symbol string
---@field body_symbol string
---@field end_symbol string
---@field buffer integer
---@field winid integer?
---@field window { style: string, border: string, relative: string, zindex: integer, focusable: boolean, height: integer, width: integer, row: integer, col: integer }
---@field extmarks table
---@field _show boolean
local Separator = {}

--- create a new separator
---@return Separator
function Separator:new()
    local buf = api.nvim_create_buf(false, true)
    api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    api.nvim_set_option_value("filetype", "colorful-winsep", { buf = buf })

    local o = {
        start_symbol = "",
        body_symbol = "",
        end_symbol = "",
        buffer = buf,
        winid = nil,
        -- for nvim_open_win
        window = {
            style = "minimal",
            border = "none",
            relative = "editor",
            zindex = 1,
            focusable = false,
            height = 1,
            width = 1,
            row = 0,
            col = 0,
        },
        extmarks = {},
        timer = uv.new_timer(),
        _show = false,
    }

    self.__index = self
    setmetatable(o, self)
    return o
end

--- vertically initialize the separator window and buffer
---@param height integer
function Separator:vertical_init(height)
    self.window.height = height
    self.window.width = 1
    local content = { self.start_symbol }
    for i = 2, height - 1 do
        content[i] = self.body_symbol
    end
    content[height] = self.end_symbol
    api.nvim_buf_set_lines(self.buffer, 0, -1, false, content)
end

--- horizontally initialize the separator window and buffer
---@param width integer
function Separator:horizontal_init(width)
    self.window.height = 1
    self.window.width = width
    local content = { self.start_symbol .. string.rep(self.body_symbol, width - 2) .. self.end_symbol }
    api.nvim_buf_set_lines(self.buffer, 0, -1, false, content)
end

--- reload the separator window config immediately
function Separator:reload_config()
    if self.winid ~= nil and api.nvim_win_is_valid(self.winid) then
        api.nvim_win_set_config(self.winid, self.window)
    end
end

---move the window to a sepcified coordinate relative to window
---@param row integer
---@param col integer
function Separator:move(row, col)
    self.window.row = row
    self.window.col = col
    self:reload_config()
end

--- show the separator window
function Separator:show()
    if api.nvim_buf_is_valid(self.buffer) then
        local win = api.nvim_open_win(self.buffer, false, self.window)
        self.winid = win
        self._show = true
        api.nvim_set_option_value("winhl", "Normal:ColorfulWinSep", { win = win })
    end
end

--- hide the separator window
function Separator:hide()
    if self.winid ~= nil and api.nvim_win_is_valid(self.winid) then
        api.nvim_win_hide(self.winid)
        self.winid = nil
        self._show = false
    end
end

return Separator
