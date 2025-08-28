local default_config = require("colorful-winsep.config")
local view = require("colorful-winsep.view")
local utils = require("colorful-winsep.utils")
local api = vim.api

local M = {
    enabled = true,
    opts = {},
}

function M.setup(user_opts)
    M.opts = vim.tbl_deep_extend("force", default_config.opts, user_opts or {})

    if type(M.opts.border) == "string" then
        M.opts.border = utils.borders[M.opts.border] or utils.borders["single"]
    end

    api.nvim_create_user_command("Winsep", function(ctx)
        local subcommand = ctx.args
        if subcommand == "enable" and not M.enabled then
            M.enabled = true
            vim.schedule(function()
                view.render(M.opts)
            end)
        elseif subcommand == "disable" and M.enabled then
            M.enabled = false
            view.hide_all()
        elseif subcommand == "toggle" then
            if M.enabled then
                view.hide_all()
            else
                vim.schedule(function()
                    view.render(M.opts)
                end)
            end
            M.enabled = not M.enabled
        else
            vim.notify("Colorful-Winsep: no command " .. ctx.args)
        end
    end, {
        nargs = 1,
        complete = function(arg)
            local list = { "enable", "disable", "toggle" }
            return vim.tbl_filter(function(s)
                return string.match(s, "^" .. arg)
            end, list)
        end,
    })

    local auto_group = api.nvim_create_augroup("colorful_winsep", { clear = true })
    api.nvim_create_autocmd({ "WinEnter", "WinResized", "BufWinEnter" }, {
        group = auto_group,
        callback = function(ctx)
            if not M.enabled then
                return
            end

            -- exclude floating windows
            local current_win = vim.fn.bufwinid(ctx.buf)
            if current_win ~= -1 then
                local win_config = api.nvim_win_get_config(current_win)
                if win_config.relative ~= nil and win_config.relative ~= "" then
                    return
                end
            end

            if vim.tbl_contains(M.opts.excluded_ft, vim.bo[ctx.buf].ft) then
                view.hide_all()
                return
            end
            vim.schedule(function()
                view.render(M.opts)
            end)
        end,
    })

    -- after loading a session, the original buffers will be removed.
    api.nvim_create_autocmd("SessionLoadPost", {
        group = auto_group,
        callback = function()
            for _, sep in pairs(view.separators) do
                sep.buffer = api.nvim_create_buf(false, true)
            end
        end,
    })

    -- for some cases that close the separators windows(fail to trigger the WinLeave event), like `:only` command
    for _, sep in pairs(view.separators) do
        api.nvim_create_autocmd({ "BufHidden" }, {
            group = auto_group,
            buffer = sep.buffer,
            callback = function()
                if not M.enabled then
                    return
                end
                sep:hide()
            end,
        })
    end
end

return M
