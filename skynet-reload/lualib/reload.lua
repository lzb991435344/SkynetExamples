local core = require "reload.core"
local skynet = require "skynet"


--lua reload 重启服务
--reload 参数

--退出后获取id,address
local function get(f, name)
	local i = 1
	repeat
		local n, v = debug.getupvalue(f, i)
		if n == name then
			return v
		end
		i = i + 1
	until n == nil
end

local function raise_error()
	local session_coroutine_id = get(skynet.exit, "session_coroutine_id")
	local session_coroutine_address = get(skynet.exit, "session_coroutine_address")
	
	for co, session in pairs(session_coroutine_id) do
		local address = session_coroutine_address[co]

		--redirect(addr, source, type, ...) 伪装成 source 地址，向 addr 发送一个消息。
		--session不为空，说明需要回应消息
		if session~=0 and address then
			skynet.redirect(address, 0, skynet.PTYPE_ERROR, session, "")
		end
	end
	local unresponse = get(skynet.exit, "unresponse")
	for resp in pairs(unresponse) do
		resp(false)
	end
end

--重启服务
local function reload(...)
	local args = SERVICE_NAME .. " " .. table.concat({...}, " ")
	local L = core.reload(args)
	core.link(L)
	raise_error()
	coroutine.yield "QUIT"	-- never return
end

return reload
