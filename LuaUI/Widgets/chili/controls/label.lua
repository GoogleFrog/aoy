--//=============================================================================

--- Label module

---@class Label : Control
---@field classname string The class name
---@field defaultWidth number Default width
---@field defaultHeight number Default height
---@field padding number[] Padding {left,top,right,bottom}
---@field autosize boolean Whether label auto-sizes
---@field autoObeyLineHeight boolean Whether to obey line height in autosize
---@field align "left"|"right"|"center" Text alignment
---@field valign "linecenter"|"ascender"|"top"|"center"|"bottom" Vertical alignment
---@field caption string Text to display
Label = Control:Inherit({
	classname = "label",

	defaultWidth = 70,
	defaultHeight = 20,

	padding = { 0, 0, 0, 0 },

	autosize = true,
	autoObeyLineHeight = true, --// (needs autosize) if true, autosize will obey the lineHeight (-> texts with the same line count will have the same height)

	align = "left",
	valign = "linecenter", --// usefull too "ascender"
	caption = "no text",
})

local this = Label
local inherited = this.inherited

--//=============================================================================

---Creates a new Label instance
---@param obj table Configuration object
---@return Label label The created label
function Label:New(obj)
	obj = inherited.New(self, obj)
	obj:SetCaption(obj.caption)
	return obj
end

--//=============================================================================

---Sets the label caption
---@param newcaption string New caption text
---@return nil
function Label:SetCaption(newcaption)
	if self.caption == newcaption then
		return
	end
	self.caption = newcaption
	self:UpdateLayout()
	self:Invalidate()
end

---Updates the label layout
---@return nil
function Label:UpdateLayout()
	local font = self.font

	if self.autosize then
		self._caption = self.caption
		local w = font:GetTextWidth(self.caption)
		local h, d, numLines = font:GetTextHeight(self.caption)

		h = h + 1
		if self.autoObeyLineHeight then
			h = math.ceil(numLines * font:GetLineHeight())
		else
			h = math.ceil(h - d)
		end

		if font.shadow then
			w = w + 2 + font.size * 0.1
			h = h + 2 + font.size * 0.1
		elseif font.outline then
			w = w + 2 + font.size * font.outlineWidth
			h = h + 2 + font.size * font.outlineWidth
		end

		local x = self.x
		local y = self.y

		if self.valign == "center" then
			y = math.round(y + (self.height - h) * 0.5)
		elseif self.valign == "bottom" then
			y = y + self.height - h
		elseif self.valign == "top" then
		else
		end

		if self.align == "left" then
		elseif self.align == "right" then
			x = x + self.width - w
		elseif self.align == "center" then
			x = math.round(x + (self.width - w) * 0.5)
		end

		self:_UpdateConstraints(x, y, w, h)
	else
		self._caption = font:WrapText(self.caption, self.width, self.height)
	end
end

---Draws the label
---@return nil
function Label:DrawControl()
	local font = self.font
	font:DrawInBox(self._caption, 0, 0, self.width, self.height, self.align, self.valign)

	if self.debug then
		gl.Color(0, 1, 0, 0.5)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
		gl.LineWidth(2)
		gl.Rect(0, 0, self.width, self.height)
		gl.LineWidth(1)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	end
end

--//=============================================================================
