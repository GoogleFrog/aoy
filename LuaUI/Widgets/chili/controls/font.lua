--//=============================================================================

--- Font module

---@class Font : Object
---@field classname string The class name
---@field font string Font filename
---@field size number Font size in pixels
---@field outlineWidth number Width of outline
---@field outlineWeight number Weight of outline
---@field shadow boolean Whether shadow is enabled
---@field outline boolean Whether outline is enabled
---@field color number[] Font color {r,g,b,a}
---@field outlineColor number[] Outline color {r,g,b,a}
---@field autoOutlineColor boolean Whether to auto-generate outline color
Font = Object:Inherit({
	font = fontfile,
	size = 12,
	outlineWidth = 3,
	outlineWeight = 3,

	shadow = false,
	outline = false,
	color = { 1, 1, 1, 1 },
	outlineColor = { 0, 0, 0, 1 },
	autoOutlineColor = true,
})

local this = Font
local inherited = this.inherited

--//=============================================================================

---Creates a new Font instance
---@param obj table Configuration object
---@return Font font The created font
function Font:New(obj)
	obj = inherited.New(self, obj)

	--// Load the font
	obj:_LoadFont()

	return obj
end

function Font:Dispose(...)
	if not self.disposed then
		FontHandler.UnloadFont(self._font)
	end
	inherited.Dispose(self, ...)
end

--//=============================================================================

function Font:_LoadFont()
	local oldfont = self._font
	local uiScale = (WG and WG.uiScale or 1)
	self._font = FontHandler.LoadFont(
		self.font,
		math.floor(self.size * uiScale),
		math.floor(self.outlineWidth * uiScale),
		self.outlineWeight
	)
	--// do this after LoadFont because it can happen that LoadFont returns the same font again
	--// but if we Unload our old one before, the gc could collect it before, so the engine would have to reload it again
	FontHandler.UnloadFont(oldfont)
end

--//=============================================================================

local function NotEqual(v1, v2)
	local t1 = type(v1)
	local t2 = type(v2)

	if t1 ~= t2 then
		return true
	end

	local isindexable = (t == "table") or (t == "metatable") or (t == "userdata")
	if not isindexable then
		return (t1 ~= t2)
	end

	for i, v in pairs(v1) do
		if v ~= v2[i] then
			return true
		end
	end
	for i, v in pairs(v2) do
		if v ~= v1[i] then
			return true
		end
	end
end

do
	--// Create some Set... methods (e.g. SetColor, SetSize, SetFont, ...)

	local params = {
		font = true,
		size = true,
		outlineWidth = true,
		outlineWeight = true,
		shadow = false,
		outline = false,
		color = false,
		outlineColor = false,
		autoOutlineColor = false,
	}

	for param, recreateFont in pairs(params) do
		local paramWithUpperCase = param:gsub("^%l", string.upper)
		local funcname = "Set" .. paramWithUpperCase

		Font[funcname] = function(self, value, ...)
			local t = type(value)

			local oldValue = self[param]

			if t == "table" then
				self[param] = table.shallowcopy(value)
			else
				local to = type(self[param])
				if to == "table" then
					--// this allows :SetColor(r,g,b,a) and :SetColor({r,g,b,a})
					local newtable = { value, ... }
					table.merge(newtable, self[param])
					self[param] = newtable
				else
					self[param] = value
				end
			end

			local p = self.parent
			if recreateFont then
				self:_LoadFont()
				if p then
					p:RequestRealign()
				end
			else
				if p and NotEqual(oldValue, self[param]) then
					p:Invalidate()
				end
			end
		end
	end

	params = nil
end

--//=============================================================================

---Gets the height of a line with this font
---@param size? number Optional size override
---@return number height Line height in pixels
function Font:GetLineHeight(size)
	return self._font.lineheight * (size or self.size)
end

---Gets the ascender height
---@param size? number Optional size override
---@return number height Ascender height in pixels
function Font:GetAscenderHeight(size)
	local font = self._font
	return (font.lineheight + font.descender) * (size or self.size)
end

---Gets the width of text with this font
---@param text string Text to measure
---@param size? number Optional size override
---@return number width Width in pixels
function Font:GetTextWidth(text, size)
	return (self._font):GetTextWidth(text) * (size or self.size)
end

---Gets the height of text with this font
---@param text string Text to measure
---@param size? number Optional size override
---@return number height Height in pixels
---@return number descender Descender height
---@return number numlines Number of lines
function Font:GetTextHeight(text, size)
	if not size then
		size = self.size
	end
	local h, descender, numlines = (self._font):GetTextHeight(text)
	return h * size, descender * size, numlines
end

function Font:WrapText(text, width, height, size)
	if not size then
		size = self.size
	end
	if (height < 1.5 * self._font.lineheight) or (width < size) then
		return text --//workaround for a bug in <=80.5.2
	end
	return (self._font):WrapText(text, width, height, size)
end

--//=============================================================================

function Font:AdjustPosToAlignment(x, y, width, height, align, valign)
	local extra = ""

	if self.shadow then
		width = width - 1 - self.size * 0.1
		height = height - 1 - self.size * 0.1
	elseif self.outline then
		width = width - 1 - self.outlineWidth
		height = height - 1 - self.outlineWidth
	end

	--// vertical alignment
	if valign == "center" then
		y = y + height / 2
		extra = "v"
	elseif valign == "top" then
		extra = "t"
	elseif valign == "bottom" then
		y = y + height
		extra = "b"
	elseif valign == "linecenter" then
		y = y + (height / 2) + (1 + self._font.descender) * self.size / 2
		extra = "x"
	else
		--// ascender
		extra = "a"
	end
	--FIXME add baseline 'd'

	--// horizontal alignment
	if align == "left" then
	--do nothing
	elseif align == "center" then
		x = x + width / 2
		extra = extra .. "c"
	elseif align == "right" then
		x = x + width
		extra = extra .. "r"
	end

	return x, y, extra
end

local function _GetExtra(align, valign)
	local extra = ""

	--// vertical alignment
	if valign == "center" then
		extra = "v"
	elseif valign == "top" then
		extra = "t"
	elseif valign == "bottom" then
		extra = "b"
	else
		--// ascender
		extra = "a"
	end

	--// horizontal alignment
	if align == "left" then
	--do nothing
	elseif align == "center" then
		extra = extra .. "c"
	elseif align == "right" then
		extra = extra .. "r"
	end

	return extra
end

--//=============================================================================

function Font:_DrawText(text, x, y, extra)
	local font = self._font

	gl.PushAttrib(GL.COLOR_BUFFER_BIT)
	gl.PushMatrix()
	gl.Scale(1, -1, 1)
	font:Begin()
	if AreInRTT() then
		gl.BlendFuncSeparate(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA, GL.ZERO, GL.ONE_MINUS_SRC_ALPHA)
	end
	font:SetTextColor(self.color)
	font:SetOutlineColor(self.outlineColor)
	font:SetAutoOutlineColor(self.autoOutlineColor)
	font:Print(text, x, -y, self.size, extra)
	font:End()
	gl.PopMatrix()
	gl.PopAttrib()
end

function Font:Draw(text, x, y, align, valign)
	if not text then
		return
	end

	local extra = _GetExtra(align, valign)
	if self.outline then
		extra = extra .. "o"
	elseif self.shadow then
		extra = extra .. "s"
	end

	self:_DrawText(text, x, y, extra)
end

function Font:DrawInBox(text, x, y, w, h, align, valign)
	if not text then
		return
	end

	local x, y, extra = self:AdjustPosToAlignment(x, y, w, h, align, valign)

	if self.outline then
		extra = extra .. "o"
	elseif self.shadow then
		extra = extra .. "s"
	end

	y = y + 1 --// FIXME: if this isn't done some chars as 'R' get truncated at the top

	self:_DrawText(text, x, y, extra)
end

Font.Print = Font.Draw
Font.PrintInBox = Font.DrawInBox

--//=============================================================================
