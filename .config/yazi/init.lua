-- use starship prompt
require("starship"):setup()

-- status bar
function Status:render(area)
	self.area = area

	local left = ui.Line({ self:size(), self:permissions() })
	local right = ui.Line({})

	return {
		ui.Paragraph(area, { left }),
		ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
		table.unpack(Progress:render(area, right:width())),
	}
end

-- borders
function Manager:render(area)
	local chunks = self:layout(area)

	local bar = function(c, x, y)
		x, y = math.max(0, x), math.max(0, y)
		return ui.Bar(ui.Rect({ x = x, y = y, w = ya.clamp(0, area.w - x, 1), h = math.min(1, area.h) }), ui.Bar.TOP)
			:symbol(c)
	end

	return ya.flat({
		ui.Border(area, ui.Border.ALL):style(THEME.manager.border_style),
		ui.Bar(chunks[3], ui.Bar.LEFT):style(THEME.manager.border_style),

		bar("┬", chunks[2].right, chunks[2].y),
		bar("┴", chunks[2].right, chunks[1].bottom - 1),

		Current:render(chunks[2]:padding(ui.Padding.xy(1))),
		Preview:render(chunks[3]:padding(ui.Padding.xy(1))),
	})
end
