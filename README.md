# inspector_key

Version: 0.0.3 (BETA)

Inspector Key is a simple keyboard tester for the LÖVE Framework. It displays a mock keyboard with Scancode and KeyConstant labels, and lights up keys as they are pressed.

![inspector_key_0_0_2](https://user-images.githubusercontent.com/23288188/203161590-e9eefe35-a4b4-40d1-a883-d2b2d71e90d2.png)


## Use cases

* Identify if certain key-combos work on your hardware (see: [Rollover](https://en.wikipedia.org/wiki/Rollover_(keyboard)))

* View your current LÖVE Scancode-KeyConstant mappings.


## Controls

Navigation is handled by the mouse. Click and drag to scroll the view, and use the mouse wheel to zoom in or out. The window is also resizable.


## To-Do

* Only scancodes associated with the standard PC keyboard are included. Maybe the others could be placed into a list entity.

* Monitor `love.textinput`

* Mac layout differences?


# License (MIT)

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
