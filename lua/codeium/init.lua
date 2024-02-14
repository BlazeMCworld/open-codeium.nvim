local worker = require("codeium.worker")

worker.send({
    type = "has_auth"
}, function(auth)
    if not auth then
        vim.notify("You need to login to use Codeium!\nUse :CodeiumLogin", vim.log.levels.ERROR)
        return
    end
end)

vim.api.nvim_create_user_command("CodeiumLogin", function()
    worker.send({
        type = "auth_url"
    }, function(url)
        local token = vim.fn.inputsecret("Please this url:\n" .. url .. "\nAnd then copy your token here: ")
        worker.send({
            type = "auth_login",
            token = token
        }, function(status)
            vim.print("Login result: " .. status)
        end)
    end)
end, {})

vim.api.nvim_create_user_command("CodeiumChat", function()
    require("codeium.chat").show()
end, {})

vim.api.nvim_create_user_command("CodeiumIndexAdd", function(opts)
    if #opts.args == 0 then
        vim.print("Missing arguments!")
        return
    end
    local path = vim.fn.fnamemodify(opts.args, ":p")
    if vim.fn.isdirectory(path) == 1 then
        worker.send({
            type = "index_dir",
            dir = path
        })
    elseif vim.fn.filereadable(path) == 1 then
        worker.send({
            type = "index_file",
            file = path
        })
    else
        vim.print("Unknown file/directory!")
    end
end, { nargs = "?", complete = "file" })

vim.loop.new_timer():start(1000, 10000, vim.schedule_wrap(function()
    worker.send({
        type = "index_cwd",
        cwd = vim.fn.getcwd()
    })
end))
vim.loop.new_timer():start(1000, 1000, vim.schedule_wrap(function()
    worker.send({
        type = "index_file",
        file = vim.fn.expand("%:p")
    })
end))

return {
    completions = require("codeium.completions")
}
