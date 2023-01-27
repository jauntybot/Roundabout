local graphics = playdate.graphics

class("Spectacle").extends()

Spectacle.kWatchTypeField = 1
Spectacle.kWatchTypeFunction = 2
Spectacle.kWatchTypeGraph = 3

function Spectacle:init(options)
	-- Options
	-- line_height: the height of each line of text as a multiple of the font height. 1.0 = actual font height.
	-- font: the font to use when drawing text. If none is specified, the current context's font will be used.
	-- lines: the number of print lines to allow on screen. Lines will be automatically be truncated if they fall offscreen.
	-- visible: whether to start in a hidden or visible state.
	-- background: the color to use behind text and graphs. Default is none, which will draw text and graphs without a background.
	
	options = options or {}
	self.line_height = options.line_height or 1.2
	if options.font then
		print('font')
		self.font = graphics.font.new(options.font)
	end
	self.max_print_lines = options.lines or 10
	print('lines '..self.max_print_lines)
	self.visible = true
	if options.visible ~= nil then
		self.visible = options.visible
	end
	self.background = options.background or nil
	
	self.watched = {}
	self.printed = {}
end

function Spectacle:show()
	self.visible = true
end

function Spectacle:hide()
	self.visible = false
end

function Spectacle:toggle()
	self.visible = not self.visible
end

function Spectacle:watch(t, field, name)
	-- Params
	-- t: either a table or a function. If a table, you must specify a field as a string to monitor (e.g. "loc.x"). If a function, the function must return an integer.
	-- field: only required if t is a table. Otherwise you can pass watch(fn, name). Supports key paths.
	-- name: optionally display a name other than the value's field. Helpful if you use a function as no name will be displayed.
	
	if type(t) == "function" then
		if field ~= nil then
			name = field
			field = nil
		end
		self.watched[#self.watched + 1] = {type=Spectacle.kWatchTypeFunction, func=t, name=name}
	else
		self.watched[#self.watched + 1] = {type=Spectacle.kWatchTypeField, table=t, field=field, name=name}
	end
end

function Spectacle:graph(t, field, options)
	-- Params
	-- t: either a table or a function. If a table, you must specify a field as a string to monitor (e.g. "loc.x"). If a function, the function must return an integer.
	-- field: only required if t is a table. Otherwise you can just pass graph(fn, options). Supports key paths.
	-- options: a table of options for this graph.
	
	-- Options
	-- period: the amount of time in seconds to collect and average samples across. 0 means no average and to display every sample.
	-- sample_width: the width in pixels that a sample should be drawn at. So how wide a bar is in a bar graph, or how long lines are in a line graph.
	-- width: the width in pixels of the graph. Pass (<number of samples you want> * sample_width) / sample_width to ensure proper visual alignment.
	-- height: the height in pixels of the graph.
	-- type: the type of graph to display. Supported: "line" or "bar".
	-- name: the name to display on the graph. This value can also be a function if you need to construct the name at runtime: function(last_sample_value) return "Value name" end
	-- min: if the automatic windowing of your values isn't working for you, you can specify a min for the bottom-most value of your graph.
	-- max: if the automatic windowing of your values isn't working for you, you can specify a max for the top-most value of your graph.
	
	-- Allow field arg to be options if t is a function.
	if type(t) == "function" then
		if type(field) == "table" then
			options = field
			field = nil
		end
	end

	options = options or {}
	local sample_period = options.period or 0.1
	local sample_width = options.sample_width or 1
	local graph_width = options.width or (math.max(60, sample_width) / sample_width)
	local graph_height = options.height or 30.0
	local graph_type = options.type or "bar"
	
	local watcher = {
		type = Spectacle.kWatchTypeGraph,
		width = graph_width,
		height = graph_height,
		name = options.name,
		graph_type = graph_type,
		min = options.min,
		max = options.max,
		sample_width = sample_width,
		sample_period = sample_period * 1000,
		current_sample = 0,
		current_sample_time = 0,
		current_sample_count = 0,
		high_watermark = 0,
		samples = table.create(math.ceil(graph_width / sample_width) + 1)
	}
	if type(t) == "function" then
		watcher.func = t
	else
		watcher.table = t
		watcher.field = field
	end
	
	self.watched[#self.watched + 1] = watcher
end

function Spectacle:unwatch(t, field)
	local is_function <const> = (type(t) == "function")
	for i, a in ipairs(self.watched) do
		if (is_function and a.func == t) or ((not is_function) and a.table == t and a.field == field) then
			table.remove(self.watched, i)
			break
		end
	end
end

function Spectacle:watchMemory()
	self:watch(function()
		local mem_bytes = tostring(math.floor(collectgarbage("count") * 1024.0))
		local formatted_mem = ""
		for i = #mem_bytes, 1, -1 do
			if #formatted_mem > 0 and (#mem_bytes - i) % 3 == 0 then
				formatted_mem = "," .. formatted_mem
			end
			formatted_mem = mem_bytes:sub(i, i) .. formatted_mem
		end
		return formatted_mem
	end, "mem")
end

function Spectacle:watchFPS(sample_count)
	self:watch(self:getFPSFunction(sample_count), "fps")
end

function Spectacle:graphFPS(sample_count, options)
	sample_count = sample_count or 100
	if type(sample_count) == "table" then
		options = sample_count
		sample_count = nil
	end
	options = options or {}
	options.name = options.name or function(latest_sample)
		return tostring(math.ceil(latest_sample)) .. " fps"
	end
	options.type = options.type or "line"
	options.period = options.period or 0
	options.height = options.height or 30.0
	self:graph(self:getFPSFunction(sample_count), options)
end

function Spectacle:print(...)
	self.printed[#self.printed + 1] = {...}
	if #self.printed > self.max_print_lines then
		table.remove(self.printed, 1)
	end
	
	-- Output to console.
	print(...)
end

function Spectacle:clear()
	self.printed = {}
end

function Spectacle:getValueForKeypath(tbl, keypath)
	local key_start = 1
	local key_end = 1
	local key_value = tbl
	local key_field = nil
	
	while true do	
		key_start = key_end
		key_end = string.find(keypath, ".", key_end, true)
		if key_end then
			key_field = string.sub(keypath, key_start, key_end-1)
			key_value = key_value[tonumber(key_field) or key_field]
			key_end += 1
		else
			key_field = string.sub(keypath, key_start, -1)
			key_value = key_value[tonumber(key_field) or key_field]
			break
		end
	end
	
	return key_value
end

function Spectacle:getFPSFunction(sample_count)
	sample_count = sample_count or 80
	
	local last_time = 0
	local sampled_time = 0
	local samples = table.create(sample_count + 1)

	return function()
		local current_time <const> = playdate.getCurrentTimeMilliseconds()
		local time_delta = (current_time - last_time) / 1000
		if last_time == 0 then time_delta = 0 end
		last_time = current_time
		
		if time_delta == 0 then
			return 0
		end
		
		if #samples == sample_count then
			sampled_time -= samples[1]
			table.remove(samples, 1)
		end
		samples[#samples + 1] = time_delta
		sampled_time += time_delta
		
		return math.ceil((1 / (sampled_time / #samples)))
	end
end

function Spectacle:updateGraph(watcher)
	local current_time <const> = playdate.getCurrentTimeMilliseconds()
	local time_delta = 0
	
	if watcher.last_sample_time ~= nil then
		time_delta = (current_time - watcher.last_sample_time)
	end
	watcher.last_sample_time = current_time
	watcher.current_sample_time += time_delta
	
	local latest_value = nil
	if watcher.func then
		latest_value = watcher.func()
	elseif watcher.table then
		latest_value = self:getValueForKeypath(watcher.table, watcher.field)
	end
	if latest_value then
		watcher.current_sample += latest_value
		watcher.current_sample_count += 1
	end
	
	if watcher.current_sample_time >= watcher.sample_period then
		if watcher.current_sample_count > 0 then
			local sample_average = watcher.current_sample / watcher.current_sample_count
			watcher.high_watermark = math.max(watcher.high_watermark, sample_average * 2)
			watcher.samples[#watcher.samples + 1] = sample_average
			local total_width = #watcher.samples * watcher.sample_width
			if watcher.graph_type == "line" then
				total_width = math.max(0, (#watcher.samples - 1) * watcher.sample_width)
			end
			if total_width > watcher.width then
				-- We now have more samples than we need to draw within this watcher's bounds.
				-- So let's remove the oldest sample, and if needed, find a new high watermark.
				if watcher.max == nil and watcher.high_watermark == watcher.samples[1] then
					watcher.high_watermark = 0
					table.remove(watcher.samples, 1)
					for _, v in ipairs(watcher.samples) do
						watcher.high_watermark = math.max(watcher.high_watermark, v * 2)
					end
				else
					table.remove(watcher.samples, 1)
				end
			end
		end
		watcher.current_sample_time = 0
		watcher.current_sample = 0
		watcher.current_sample_count = 0
	end

end

function Spectacle:drawGraph(x, y, font_height, padding, watcher)
	if self.background ~= nil then
		graphics.setColor(self.background)
		graphics.fillRect(x - padding, y - padding / 2, watcher.width + padding * 2, watcher.height + padding)
		
		if self.background == graphics.kColorBlack then
			graphics.setColor(graphics.kColorWhite)
		elseif self.background == graphics.kColorWhite then
			graphics.setColor(graphics.kColorBlack)
		else
			graphics.setColor(graphics.kColorXOR)
		end
	else
		graphics.setColor(graphics.kColorXOR)
	end
	
	local max_value = watcher.max or watcher.high_watermark
	local min_value = watcher.min or 0
	
	if watcher.graph_type == "bar" then
		for i, v in ipairs(watcher.samples) do
			local sample_height <const> = math.max(0, watcher.height * (math.max(0, v - min_value) / max_value))
			graphics.fillRect(x + (i - 1) * watcher.sample_width, (y + watcher.height) - sample_height, watcher.sample_width, sample_height)
		end
	elseif watcher.graph_type == "line" then
		local previous_height = nil
		graphics.setStrokeLocation(graphics.kStrokeCentered)
		graphics.setLineCapStyle(graphics.kLineCapStyleSquare)
		
		for i, v in ipairs(watcher.samples) do
			local sample_height <const> = math.max(0, watcher.height * (math.max(0, v - min_value) / max_value))
			if previous_height then
				graphics.drawLine(x + (i - 2) * watcher.sample_width, (y + watcher.height) - previous_height, x + (i - 1) * watcher.sample_width, (y + watcher.height) - sample_height)
			end
			previous_height = sample_height
		end
	end
	
	if watcher.name then
		local name = watcher.name
		if type(name) == "function" then
			if #watcher.samples > 0 then
				name = tostring(name(watcher.samples[#watcher.samples]))
			else
				name = ""
			end
		end
		name = name:gsub("_", "__"):gsub("*", "**")
		graphics.setImageDrawMode(graphics.kDrawModeNXOR)
		graphics.drawText(name, x, y + watcher.height - font_height)
	end
end

function Spectacle:drawText(x, y, font, font_height, padding, text)
	text = text:gsub("_", "__"):gsub("*", "**")
	if self.background ~= nil then
		graphics.setColor(self.background)
		graphics.fillRect(x - padding, y - padding / 2, font:getTextWidth(text) + padding * 2, font_height + padding)
	end
	graphics.setImageDrawMode(graphics.kDrawModeNXOR)
	graphics.drawText(text, x, y)
end

function Spectacle:draw(x, y)
	-- Basically no overhead when hidden.
	if not self.visible then
		return
	end
	
	x = x or 5
	y = y or 5
	
	local old_mode <const> = graphics.getImageDrawMode()
	graphics.setImageDrawMode(graphics.kDrawModeNXOR)
	
	local old_font <const> = graphics.getFont()
	local font_height = old_font:getHeight()
	local current_font = old_font
	if self.font then
		print('set font')
		graphics.setFont(self.font)
		font_height = self.font:getHeight()
		current_font = self.font
	end
	
	local line_spacing <const> = math.ceil(font_height * self.line_height) - font_height
	
	-- Draw watched values.
	for i, item in ipairs(self.watched) do
		if item.type == Spectacle.kWatchTypeFunction then
			local value = item.func()
			local name = item.name
			local text = ""
			if name then text = tostring(name)..": " end
			text = text .. tostring(value)
			self:drawText(x, y, current_font, font_height, line_spacing, text)
			y += font_height + line_spacing
		elseif item.type == Spectacle.kWatchTypeField then
			local value = self:getValueForKeypath(item.table, item.field)
			local name = item.name or item.field
			local text = ""
			if name then text = tostring(name)..": " end
			text = text .. tostring(value)
			self:drawText(x, y, current_font, font_height, line_spacing, text)
			y += font_height + line_spacing
		elseif item.type == Spectacle.kWatchTypeGraph then
			self:updateGraph(item)
			self:drawGraph(x, y, font_height, line_spacing, item)
			y += item.height + line_spacing
		end
	end
	
	-- Draw print values.
	if #self.printed > 0 then
		y += line_spacing
		for i = #self.printed, math.max(#self.printed-self.max_print_lines+1, 1), -1 do
			if y > 240 - line_spacing * 2 then
				break
			end
			item = self.printed[i]
			local text = nil
			for i, x in ipairs(item) do
				if text == nil then
					text = tostring(x)
				else
					text = text .. " " .. tostring(x)
				end
			end
			if text then
				self:drawText(x, y, current_font, font_height, line_spacing, text)
			end
			y += font_height + line_spacing
		end
	end
	
	-- Restore graphics context.
	graphics.setImageDrawMode(old_mode)
	if old_font then
		graphics.setFont(old_font)
	end
end