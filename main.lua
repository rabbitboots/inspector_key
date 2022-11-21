
-- Name: Inspector Key
-- Version 0.0.1 (Beta) (Last updated: 19 Nov 2022)
-- Supported LÖVE versions: 11.4

-- Description: Displays a mock PC keyboard with Scancode and KeyConstant labels, and
-- lights up keys as they are pressed.

-- Controls: Because all keys are required for the test, view navigation is handled by the mouse.
-- * Click + drag to scroll, mouse wheel up/down to zoom. The window is resizable as well.
-- * Use the key combo 'Shift+Esc' to quit.


--[[
MIT License

Copyright (c) 2022 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


--[[
TODO:
* Add a separate list of scancodes that don't appear on the standard layout.
* Mac layout differences?
* Maybe include an alternative, laptop-shaped keyboard as well.
--]]


local ins_font = love.graphics.newFont(15)
love.graphics.setFont(ins_font)


-- Scrolling, scaling controlled by the mouse.
local scroll_x = 0
local scroll_y = 0
local scale_xy = 1.0
local scale_xy_min = 0.1
local scale_xy_max = 100.0


local colors = {
	kb_main_body = {0.2, 0.2, 0.4, 1.0},
	kb_main_outline = {0.1, 0.1, 0.1, 1.0},

	kb_key_outline = {0.8, 0.8, 0.8, 1.0},
	kb_key_body = {0.25, 0.25, 0.25, 1.0},
	kb_key_body_active = {0.4, 0.4, 0.4, 1.0},

	kb_text_sc = {1.0, 1.0, 0.0, 1.0},
	kb_text_kc = {0.0, 1.0, 1.0, 1.0},
	kb_text_active = {0.0, 0.0, 0.0, 1.0},

	kb_active_element = {1.0, 1.0, 1.0, 1.0},
}
local line_states = {
	kb_main_outline = {join = "miter", width = 2, style = "smooth"},
	kb_key_outline = {join = "miter", width = 2, style = "smooth"},
	kb_active_element = {join = "miter", width = 4, style = "smooth"},
}

local function setLineState(state)
	love.graphics.setLineJoin(state.join)
	love.graphics.setLineWidth(state.width)
	love.graphics.setLineStyle(state.style)
end


-- Common measurements.

local key_len = 64 -- width and height of a standard key
local key_gap0 = 38 -- various gaps between keys and key-groups
local key_gap1 = 32
local key_gap2 = 16
local key_gap3 = 8
local key_gap4 = 4


-- Sets up a key within the mock keyboard diagram.
local function newKey(scancode, w, h, gap_left)
	if not scancode then error("missing scancode", 2)
	elseif not w then error("missing w", 2)
	elseif not h then error("missing h", 2)
	elseif not gap_left then error("missing gap_left", 2)
	end

	return {scancode = scancode, x = 0, y = 0, w = w, h = h, gap_left = gap_left}
end


-- Our mock keyboard. Final dimensions and layout are set up a bit later.
local mock_kb = {

	x = 0,
	y = 0,
	w = 1,
	h = 1,

	-- These gaps are on the top side.
	row_gaps = {
		key_gap4, -- 1: esc, f-keys
		key_len + key_gap2, -- 2; number row
		key_len + key_gap4, -- 3: tab, qwerty
		key_len + key_gap4, -- 4: caps lock, asdfg
		key_len + key_gap4, -- 5: shift, zxcv
		key_len + key_gap4, -- 6: space row
	},

	rows = {
		{
			x = 0,
			y = 0,
			newKey("escape", key_len, key_len, key_gap4),

			newKey("f1", key_len, key_len, key_len + key_gap4*2),
			newKey("f2", key_len, key_len, key_gap4),
			newKey("f3", key_len, key_len, key_gap4),
			newKey("f4", key_len, key_len, key_gap4),

			newKey("f5", key_len, key_len, key_gap0),
			newKey("f6", key_len, key_len, key_gap4),
			newKey("f7", key_len, key_len, key_gap4),
			newKey("f8", key_len, key_len, key_gap4),

			newKey("f9", key_len, key_len, key_gap0),
			newKey("f10", key_len, key_len, key_gap4),
			newKey("f11", key_len, key_len, key_gap4),
			newKey("f12", key_len, key_len, key_gap4),

			newKey("printscreen", key_len, key_len, key_gap2),
			newKey("scrolllock", key_len, key_len, key_gap4),
			newKey("pause", key_len, key_len, key_gap4),
		}, {
			newKey("`", key_len, key_len, key_gap4),
			newKey("1", key_len, key_len, key_gap4),
			newKey("2", key_len, key_len, key_gap4),
			newKey("3", key_len, key_len, key_gap4),
			newKey("4", key_len, key_len, key_gap4),
			newKey("5", key_len, key_len, key_gap4),
			newKey("6", key_len, key_len, key_gap4),
			newKey("7", key_len, key_len, key_gap4),
			newKey("8", key_len, key_len, key_gap4),
			newKey("9", key_len, key_len, key_gap4),
			newKey("0", key_len, key_len, key_gap4),
			newKey("-", key_len, key_len, key_gap4),
			newKey("=", key_len, key_len, key_gap4),
			newKey("backspace", key_len * 2 + key_gap4, key_len, key_gap4), -- 2x wide key

			newKey("insert", key_len, key_len, key_gap2),
			newKey("home", key_len, key_len, key_gap4),
			newKey("pageup", key_len, key_len, key_gap4),

			newKey("numlock", key_len, key_len, key_gap2),
			newKey("kp/", key_len, key_len, key_gap4),
			newKey("kp*", key_len, key_len, key_gap4),
			newKey("kp-", key_len, key_len, key_gap4),
		}, {
			newKey("tab", math.floor(0.5 + key_len * 1.5), key_len, key_gap4),
			newKey("q", key_len, key_len, key_gap4),
			newKey("w", key_len, key_len, key_gap4),
			newKey("e", key_len, key_len, key_gap4),
			newKey("r", key_len, key_len, key_gap4),
			newKey("t", key_len, key_len, key_gap4),
			newKey("y", key_len, key_len, key_gap4),
			newKey("u", key_len, key_len, key_gap4),
			newKey("i", key_len, key_len, key_gap4),
			newKey("o", key_len, key_len, key_gap4),
			newKey("p", key_len, key_len, key_gap4),
			newKey("[", key_len, key_len, key_gap4),
			newKey("]", key_len, key_len, key_gap4),
			newKey("\\", math.floor(0.5 + key_len * 1.5) + key_gap4, key_len, key_gap4), -- 1.5x wide key

			newKey("delete", key_len, key_len, key_gap2),
			newKey("end", key_len, key_len, key_gap4),
			newKey("pagedown", key_len, key_len, key_gap4),

			newKey("kp7", key_len, key_len, key_gap2),
			newKey("kp8", key_len, key_len, key_gap4),
			newKey("kp9", key_len, key_len, key_gap4),
			newKey("kp+", key_len, key_len*2 + key_gap4, key_gap4),
		}, {
			newKey("capslock", math.floor(0.5 + key_len * 1.75) + key_gap4, key_len, key_gap4),
			newKey("a", key_len, key_len, key_gap4),
			newKey("s", key_len, key_len, key_gap4),
			newKey("d", key_len, key_len, key_gap4),
			newKey("f", key_len, key_len, key_gap4),
			newKey("g", key_len, key_len, key_gap4),
			newKey("h", key_len, key_len, key_gap4),
			newKey("j", key_len, key_len, key_gap4),
			newKey("k", key_len, key_len, key_gap4),
			newKey("l", key_len, key_len, key_gap4),
			newKey(";", key_len, key_len, key_gap4),
			newKey("'", key_len, key_len, key_gap4),
			newKey("return", math.floor(0.5 + key_len*2.25) + key_gap4, key_len, key_gap4),

			newKey("kp4", key_len, key_len, key_gap2 + (key_len*3 + key_gap4*2) + key_gap2),
			newKey("kp5", key_len, key_len, key_gap4),
			newKey("kp6", key_len, key_len, key_gap4),
		}, {
			newKey("lshift", math.floor(0.5 + key_len*2.5), key_len, key_gap4),
			newKey("z", key_len, key_len, key_gap4),
			newKey("x", key_len, key_len, key_gap4),
			newKey("c", key_len, key_len, key_gap4),
			newKey("v", key_len, key_len, key_gap4),
			newKey("b", key_len, key_len, key_gap4),
			newKey("n", key_len, key_len, key_gap4),
			newKey("m", key_len, key_len, key_gap4),
			newKey(",", key_len, key_len, key_gap4),
			newKey(".", key_len, key_len, key_gap4),
			newKey("/", key_len, key_len, key_gap4),
			newKey("rshift", math.floor(0.5 + key_len*2.5) + key_gap4*3, key_len, key_gap4),

			newKey("up", key_len, key_len, key_len + key_gap2 + key_gap4),

			newKey("kp1", key_len, key_len, key_len + key_gap2 + key_gap4),
			newKey("kp2", key_len, key_len, key_gap4),
			newKey("kp3", key_len, key_len, key_gap4),
			newKey("kpenter", key_len, key_len*2 + key_gap4, key_gap4),
		}, {
			newKey("lctrl", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),
			newKey("lgui", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),
			newKey("lalt", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),
			newKey("space", key_len * 7, key_len, key_gap4),
			newKey("ralt", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),
			newKey("rgui", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),
			newKey("menu", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),
			newKey("rctrl", math.floor(0.5 + key_len * 1.2), key_len, key_gap4),

			newKey("left", key_len, key_len, key_gap2),
			newKey("down", key_len, key_len, key_gap4),
			newKey("right", key_len, key_len, key_gap4),

			newKey("kp0", key_len*2 + key_gap4, key_len, key_gap2),
			newKey("kp.", key_len, key_len, key_gap4),
		},
	},
}


local function arrangeMockKeyboard(kb)

	-- Place each key and calculate the total keyboard size.
	-- Horizontal key position is cumulative per-row.

	local w, h = 1, 1

	local yy = 0
	for i, row in ipairs(kb.rows) do
		local xx = 0
		yy = yy + kb.row_gaps[i]

		for j, key in ipairs(row) do
			key.y = yy

			xx = xx + key.gap_left
			key.x = xx
			xx = xx + key.w

			w = math.max(w, key.x + key.w)
			h = math.max(h, key.y + key.h)
		end
	end

	kb.w = w + key_gap4
	kb.h = h + key_gap4
end


do
	arrangeMockKeyboard(mock_kb)

	-- Center scrolling on the mock keyboard.
	scroll_x = math.floor(0.5 - mock_kb.w/2)
	scroll_y = math.floor(0.5 - mock_kb.h/2)

	-- Pre-scale the keyboard to fit the starting window.
	scale_xy = love.graphics.getWidth() / math.max(1, mock_kb.w)
end



function love.keypressed(kc, sc, rep)

	if kc == "escape" and love.keyboard.isDown("lshift", "rshift") then
		love.event.quit()
		return
	end
end


-- function love.keyreleased(kc, sc, rep)


local down_mouse = {} -- hash (not array) of pressed mouse buttons.
function love.mousepressed(x, y, button, istouch, presses)
	down_mouse[button] = true
end


function love.mousereleased(x, y, button, istouch, presses)
	down_mouse[button] = nil
end


function love.mousemoved(x, y, dx, dy, istouch)

	if down_mouse[1] then
		scroll_x = scroll_x + dx / math.max(0.001, scale_xy)
		scroll_y = scroll_y + dy / math.max(0.001, scale_xy)
	end
end


function love.wheelmoved(x, y)
	-- Zoom in or out.
	if y ~= 0 then
		scale_xy = math.max(scale_xy_min, math.min(scale_xy + (scale_xy * 0.0625 * y), scale_xy_max))
	end
end


function love.update(dt)
	-- n/a
end


function love.draw()

	local mx, my = love.mouse.getPosition()
	local wx, wy = love.graphics.getDimensions()

	-- Move camera
	love.graphics.translate(math.floor(wx/2), math.floor(wy/2))
	love.graphics.scale(scale_xy, scale_xy)
	love.graphics.translate(math.floor(0.5 + scroll_x), math.floor(0.5 + scroll_y))

	-- Draw main keyboard body
	love.graphics.setColor(colors.kb_main_body)
	love.graphics.rectangle("fill", 0.5 + mock_kb.x, 0.5 + mock_kb.y, mock_kb.w - 1, mock_kb.h - 1)

	love.graphics.setColor(colors.kb_main_outline)
	setLineState(line_states.kb_main_outline)
	love.graphics.rectangle("line", 0.5 + mock_kb.x, 0.5 + mock_kb.y, mock_kb.w - 1, mock_kb.h - 1)

	-- Draw each key
	for i, row in ipairs(mock_kb.rows) do
		for j, key in ipairs(row) do

			local key_from_code = love.keyboard.getKeyFromScancode(key.scancode)

			local key_active = love.keyboard.isDown(key_from_code)
			local scan_active = love.keyboard.isScancodeDown(key.scancode)

			-- Key body
			love.graphics.setColor((scan_active or key_active) and colors.kb_key_body_active or colors.kb_key_body)
			love.graphics.rectangle("fill", 0.5 + key.x, 0.5 + key.y, key.w - 1, key.h - 1, 2, 2)

			love.graphics.setColor(colors.kb_key_outline)
			setLineState(line_states.kb_key_outline)
			love.graphics.rectangle("line", 0.5 + key.x, 0.5 + key.y, key.w - 1, key.h - 1, 2, 2)

			if scan_active then
				setLineState(line_states.kb_active_element)
				love.graphics.rectangle("line", 0.5 + key.x, 0.5 + key.y, key.w - 1, key.h - 1, 2, 2)
			end

			-- Scancode label
			love.graphics.setColor(scan_active and colors.kb_text_active or colors.kb_text_sc)
			love.graphics.printf(key.scancode, key.x, key.y, key.w, "center")

			if key_active then
				love.graphics.setColor(colors.kb_active_element)
			end

			-- KeyConstant label
			love.graphics.setColor(key_active and colors.kb_text_active or colors.kb_text_kc)
			love.graphics.printf(key_from_code, key.x, key.y + math.floor(key.h/2), key.w, "center")
		end
	end

	-- Demo controls listing
	love.graphics.origin()
	love.graphics.setColor(0, 0, 0, 0.8)
	local dh = 32
	local dy = wy - dh
	love.graphics.rectangle("fill", 0, dy, wx, dh)
	love.graphics.setColor(1,1,1,1)
	love.graphics.print("Top: Scancodes, bottom: KeyConstants\tClick+drag to scroll\tMousewheel to zoom\tShift+Esc to quit", 8, dy + 8)
end

