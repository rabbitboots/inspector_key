
-- Name: Inspector Key
-- Version 0.0.3 (Beta)
-- Supported LÖVE versions: 11.4

-- Description: Displays a mock PC keyboard with Scancode and KeyConstant labels, and
-- lights up keys as they are pressed.

-- Controls: Because all keys are required for the test, view navigation is handled by the mouse.
-- * Click + drag to scroll, mouse wheel up/down to zoom. The window is resizable as well.
-- * Use 'Alt+F4' to quit.

--[[
	Beta changelog:
	* 0.0.3: (2023-OCT-16)
		* Replaced 'menu' scancode with 'application' between 'rgui' and 'rctrl'.
		* Removed the version check in conf.lua.
		* Removed the exit keyboard shortcut.

	* 0.0.2: (2022-NOV-21)
		* Simplified how mock keys are positioned and spaced
		* Added function to dump the current mock keyboard layout to the terminal/console as a table
		* Color scheme: darkened key outlines while idle
		* Mouse buttons 1, 2 and 3 all initiate scrolling now
		* Started changelog
--]]

--[[
MIT License

Copyright (c) 2022, 2023 RBTS

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
* State of modkeys (numlock, etc -- LÖVE 12 adds 'love.keyboard.isModifierActive')
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

	kb_key_outline = {0.1, 0.1, 0.1, 1.0},
	kb_key_outline_active = {0.8, 0.8, 0.8, 1.0},
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

local key_size_normal = 64 -- width and height of a standard key
local key_size_half = math.floor(0.5 + key_size_normal / 2)
local key_size_quarter = math.floor(0.5 + key_size_normal / 4)

-- various gaps between keys and key-groups
local key_gap2 = 16
local key_gap4 = 4
local key_gap8 = 2


-- Sets up a key within the mock keyboard diagram.
local function newKey(scancode, w, h)
	h = h or w

	if not scancode then error("missing scancode", 2)
	elseif not w then error("missing w", 2)
	elseif not h then error("missing h", 2)
	end

	return {scancode = scancode, x = 0, y = 0, w = w, h = h}
end


local function newHorizontalGap(w)

	if not w then error("missing w", 2)
	end

	return {is_gap = true, w = w}
end


local function trimKey(key, left, right, top, bottom)

	key.x = key.x + left
	key.y = key.y + top
	key.w = key.w - (left + right)
	key.h = key.h - (top + bottom)
end


--- Dumps the contents of the mock keyboard to the terminal. Feel free to use. See arrangeMockKeyboard for commented-out
--  lines that call this.
local function dumpMockKeyboard(kb)
	io.write(
		"{\n" ..
		"\tx = " .. kb.x .. ",\n" ..
		"\ty = " .. kb.y .. ",\n" ..
		"\tw = " .. kb.w .. ",\n" ..
		"\th = " .. kb.h .. ",\n"
	)

	io.write("\trows = {\n")

	for i, row in ipairs(kb.rows) do
		io.write("\t\t{\n")
		for j = 1, #row do
			local key = row[j]
			if not key.is_gap then
				-- Fix escaped strings
				local escaped_scancode = key.scancode
				if escaped_scancode == [[\]] then
					escaped_scancode = [[\\]]
				end
				io.write("\t\t\t{scancode = \"" .. escaped_scancode .. "\", x = " .. key.x .. ", y = " .. key.y .. ", w = " .. key.w .. ", h = " .. key.h .. "},\n")
			end
		end
		io.write("\t\t},\n")
	end

	io.write("\t}\n}\n")
end
--]]


-- Our mock keyboard. Final dimensions and layout are set up a bit later.
local function newMockKeyboardUS()
	return {
		x = 0,
		y = 0,
		w = 1,
		h = 1,

		-- Cumulative Y start position for each row.
		row_offsets = {
			0, -- 1: esc, f-keys
			key_size_normal + key_gap2, -- 2; number row
			key_size_normal, -- 3: tab, qwerty
			key_size_normal, -- 4: caps lock, asdfg
			key_size_normal, -- 5: shift, zxcv
			key_size_normal, -- 6: space row
		},

		rows = {
			{
				x = 0,
				y = 0,

				newKey("escape", key_size_normal),

				newHorizontalGap(key_size_normal),

				newKey("f1", key_size_normal),
				newKey("f2", key_size_normal),
				newKey("f3", key_size_normal),
				newKey("f4", key_size_normal),

				newHorizontalGap(key_size_half),

				newKey("f5", key_size_normal),
				newKey("f6", key_size_normal),
				newKey("f7", key_size_normal),
				newKey("f8", key_size_normal),

				newHorizontalGap(key_size_half),

				newKey("f9", key_size_normal),
				newKey("f10", key_size_normal),
				newKey("f11", key_size_normal),
				newKey("f12", key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("printscreen", key_size_normal),
				newKey("scrolllock", key_size_normal),
				newKey("pause", key_size_normal),
			},
			{
				newKey("`", key_size_normal),
				newKey("1", key_size_normal),
				newKey("2", key_size_normal),
				newKey("3", key_size_normal),
				newKey("4", key_size_normal),
				newKey("5", key_size_normal),
				newKey("6", key_size_normal),
				newKey("7", key_size_normal),
				newKey("8", key_size_normal),
				newKey("9", key_size_normal),
				newKey("0", key_size_normal),
				newKey("-", key_size_normal),
				newKey("=", key_size_normal),
				newKey("backspace", key_size_normal * 2, key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("insert", key_size_normal),
				newKey("home", key_size_normal),
				newKey("pageup", key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("numlock", key_size_normal),
				newKey("kp/", key_size_normal),
				newKey("kp*", key_size_normal),
				newKey("kp-", key_size_normal),

			},
			{
				newKey("tab", math.floor(0.5 + key_size_normal * 1.5), key_size_normal),
				newKey("q", key_size_normal),
				newKey("w", key_size_normal),
				newKey("e", key_size_normal),
				newKey("r", key_size_normal),
				newKey("t", key_size_normal),
				newKey("y", key_size_normal),
				newKey("u", key_size_normal),
				newKey("i", key_size_normal),
				newKey("o", key_size_normal),
				newKey("p", key_size_normal),
				newKey("[", key_size_normal),
				newKey("]", key_size_normal),
				newKey("\\", math.floor(0.5 + key_size_normal * 1.5), key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("delete", key_size_normal),
				newKey("end", key_size_normal),
				newKey("pagedown", key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("kp7", key_size_normal),
				newKey("kp8", key_size_normal),
				newKey("kp9", key_size_normal),
				newKey("kp+", key_size_normal, key_size_normal * 2), -- extends down into the next row
			},
			{
				newKey("capslock", math.floor(0.5 + key_size_normal * 1.75), key_size_normal),
				newKey("a", key_size_normal),
				newKey("s", key_size_normal),
				newKey("d", key_size_normal),
				newKey("f", key_size_normal),
				newKey("g", key_size_normal),
				newKey("h", key_size_normal),
				newKey("j", key_size_normal),
				newKey("k", key_size_normal),
				newKey("l", key_size_normal),
				newKey(";", key_size_normal),
				newKey("'", key_size_normal),
				newKey("return", math.floor(0.5 + key_size_normal * 2.25), key_size_normal),

				newHorizontalGap(key_size_quarter + key_size_normal * 3 + key_size_quarter),

				newKey("kp4", key_size_normal),
				newKey("kp5", key_size_normal),
				newKey("kp6", key_size_normal),
				-- (kp+ extends to here.)
			},
			{
				newKey("lshift", math.floor(0.5 + key_size_normal * 2.5), key_size_normal),
				newKey("z", key_size_normal),
				newKey("x", key_size_normal),
				newKey("c", key_size_normal),
				newKey("v", key_size_normal),
				newKey("b", key_size_normal),
				newKey("n", key_size_normal),
				newKey("m", key_size_normal),
				newKey(",", key_size_normal),
				newKey(".", key_size_normal),
				newKey("/", key_size_normal),
				newKey("rshift", math.floor(0.5 + key_size_normal * 2.5), key_size_normal),

				newHorizontalGap(key_size_quarter + key_size_normal),

				newKey("up", key_size_normal),

				newHorizontalGap(key_size_quarter + key_size_normal),

				newKey("kp1", key_size_normal),
				newKey("kp2", key_size_normal),
				newKey("kp3", key_size_normal),
				newKey("kpenter", key_size_normal, key_size_normal * 2), -- extends down to next row
			},
			{
				newKey("lctrl", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),
				newKey("lgui", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),
				newKey("lalt", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),
				newKey("space", math.floor(0.5 + key_size_normal * 1.25 * 5), key_size_normal), -- roughly 5 'ctrl' keys long
				newKey("ralt", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),
				newKey("rgui", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),
				newKey("application", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),

				newKey("rctrl", math.floor(0.5 + key_size_normal * 1.25), key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("left", key_size_normal),
				newKey("down", key_size_normal),
				newKey("right", key_size_normal),

				newHorizontalGap(key_size_quarter),

				newKey("kp0", math.floor(0.5 + key_size_normal * 2), key_size_normal),
				newKey("kp.", key_size_normal),
				-- 'kpenter' extends to this spot.
			},
		},
	}
end


local function arrangeMockKeyboard(kb)

	-- Place each key and calculate the total keyboard size.
	-- Keys are placed left-to-right.

	local w, h = 1, 1

	local yy = key_gap4

	for i, row in ipairs(kb.rows) do
		local xx = key_gap4
		yy = yy + kb.row_offsets[i]

		for j, key in ipairs(row) do
			if not key.is_gap then
				key.x = xx
				key.y = yy

				w = math.max(w, key.x + key.w)
				h = math.max(h, key.y + key.h)
			end

			xx = xx + key.w
		end
	end

	kb.w = w + key_gap4
	kb.h = h + key_gap4

	-- Remove gap tables and trim the sizes of keys.
	for i, row in ipairs(kb.rows) do
		for j = #row, 1, -1 do
			if row[j].is_gap then
				table.remove(row, j)
			else
				trimKey(row[j], key_gap8, key_gap8, key_gap8, key_gap8)
			end
		end
	end

	-- Layout dump. Place above the loop to get the pre-trimmed version.
	--dumpMockKeyboard(kb)
end


-- Demo initialization
local mock_kb
do
	mock_kb = newMockKeyboardUS()
	arrangeMockKeyboard(mock_kb)

	-- Center scrolling on the mock keyboard.
	scroll_x = math.floor(0.5 - mock_kb.w/2)
	scroll_y = math.floor(0.5 - mock_kb.h/2)

	-- Pre-scale the keyboard to fit the starting window.
	scale_xy = love.graphics.getWidth() / math.max(1, mock_kb.w)
end



--function love.keypressed(kc, sc, rep)
--function love.keyreleased(kc, sc, rep)


local down_mouse = {} -- hash (not array) of pressed mouse buttons.
function love.mousepressed(x, y, button, istouch, presses)
	down_mouse[button] = true
end


function love.mousereleased(x, y, button, istouch, presses)
	down_mouse[button] = nil
end


function love.mousemoved(x, y, dx, dy, istouch)

	if down_mouse[1] or down_mouse[2] or down_mouse[3] then
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

			love.graphics.setColor((scan_active or key_active) and colors.kb_key_outline_active or colors.kb_key_outline)
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

