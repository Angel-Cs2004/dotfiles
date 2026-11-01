--- @sync entry
return {
	entry = function()
		local h = cx.active.current.hovered
		if h then
			if h.cha.is_dir then
				local path = ya.quote(h.url:path())
				ya.emit("shell", {
					cmd = "cd -- " .. path .. " && exec /usr/bin/nvim .",
					block = true,
				})
			else
				ya.emit("open", { hovered = true })
			end
		end
	end,
}
