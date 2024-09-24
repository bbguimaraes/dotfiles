function machinatrix_command(_, buffer, args)
    local cmd <const> = "machinatrix " .. args
    weechat.command(buffer, cmd)
    assert(weechat.hook_process(cmd, 0, "machinatrix_process_callback", buffer))
end

function machinatrix_process_callback(buffer, command, return_code, out, err)
    if return_code == weechat.WEECHAT_HOOK_PROCESS_ERROR then
        weechat.print("", "Error with command " .. command)
        return weechat.WEECHAT_RC_ERROR
    end
    if out ~= "" then
        weechat.buffer_set(buffer, "input", out)
        weechat.buffer_set(buffer, "input_pos", #out)
        weechat.buffer_set(buffer, "input_multiline", 1)
    end
    if err ~= "" then
        weechat.print("", "machinatrix: " .. err)
    end
    if 0 <= return_code then
        if return_code ~= 0 then
            weechat.print("", "machinatrix return_code: " .. return_code)
            return weechat.WEECHAT_RC_ERROR
        end
    end
    return WEECHAT_RC_OK
end

local cmd_name <const> = "machinatrix"
local cmd_desc <const> =
    "send `machinatrix` output as a message in the current buffer"
local cmd_callback <const> = "machinatrix_command"

assert(weechat.register(
    "machinatrix", "bbguimaraes", "0.0.1", "GPLv3", "machinatrix", "", ""))
assert(weechat.hook_command(cmd_name, cmd_desc, "", "", "", cmd_callback, ""))
