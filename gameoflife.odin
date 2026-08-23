// Pars SARICA

package main

import rl "vendor:raylib"
import "core:fmt"

HorizontalCount : i32 : 40
VerticalCount : i32 : 40
BoxSize : i32 : 15

ButtonWidth : i32 : 400
ButtonHeight : i32 : 100

ClearButtonWidth : i32 : 200
ClearButtonHeight : i32 : 100

NextButtonWidth : i32 : 200
NextButtonHeight : i32 : 100

Box :: struct {
	x: i32,
	y: i32,
	isfull: bool
}

calc_start :: proc() -> (xstart, ystart: i32) {
	xstart = (rl.GetRenderWidth() - BoxSize * HorizontalCount) / 2
	ystart = (rl.GetRenderHeight() - BoxSize * VerticalCount) / 2
	return
}

render :: proc(boxes: #soa[]Box)
{
	xstart, ystart := calc_start()

	if HorizontalCount * VerticalCount != i32(len(boxes))
	{
		return
	}

	counter := 0
	for i: i32 = 0; i < VerticalCount; i += 1
	{
		for j: i32 = 0; j < HorizontalCount; j += 1
		{
			rl.DrawRectangle(xstart + j * BoxSize, ystart + i * BoxSize, BoxSize, BoxSize, rl.BLACK)
			rl.DrawRectangle(xstart + j * BoxSize + 1, ystart + i * BoxSize + 1, BoxSize - 1, BoxSize - 1, boxes[counter].isfull ? rl.YELLOW : rl.GRAY)
			counter += 1
		}
	}
}

calc_box_pressed :: proc(boxes: #soa[]Box, mousex, mousey: i32) {
	xstart, ystart := calc_start()
	xend := xstart + BoxSize * HorizontalCount
	yend := ystart + BoxSize * VerticalCount

	if mousex < xstart || mousex > xend || mousey < ystart || mousey > yend
	{
		return
	}

	for &box in boxes
	{
		pixelx := xstart + box.x * BoxSize
		pixely := ystart + box.y * BoxSize
		if mousex >= pixelx && mousex <= pixelx + BoxSize && mousey >= pixely && mousey <= pixely + BoxSize
		{
			box.isfull = !box.isfull
		}
	}
}

neighbor_count :: proc(boxes: #soa[]Box, id: i32) -> (count: int = 0)
{
	if id % HorizontalCount != 0 && id - 1 >= 0 && boxes[id - 1].isfull {
		count += 1
	}

	if (id + 1) % HorizontalCount != 0 && id + 1 < i32(len(boxes)) && boxes[id + 1].isfull {
		count += 1
	}

	if id > HorizontalCount - 1 && id - HorizontalCount >= 0 && boxes[id - HorizontalCount].isfull {
		count += 1
	}

	if id > HorizontalCount - 1 && id % HorizontalCount != 0 && id - HorizontalCount - 1 >= 0 && boxes[id - HorizontalCount - 1].isfull {
		count += 1
	}

	if id > HorizontalCount - 1 && (id + 1) % HorizontalCount != 0 && id - HorizontalCount + 1 >= 0 && boxes[id - HorizontalCount + 1].isfull {
		count += 1
	}

	if id < HorizontalCount * (VerticalCount - 1) && id + HorizontalCount < i32(len(boxes)) && boxes[id + HorizontalCount].isfull {
		count += 1
	}

	if id < HorizontalCount * (VerticalCount - 1) && id + HorizontalCount - 1 < i32(len(boxes)) && boxes[id + HorizontalCount - 1].isfull {
		count += 1
	}

	if id < HorizontalCount * (VerticalCount - 1) && (id + 1) % HorizontalCount != 0 && id + HorizontalCount + 1 < i32(len(boxes)) && boxes[id + HorizontalCount + 1].isfull {
		count += 1
	}

	return
}

update_boxes :: proc(boxes: #soa[]Box)
{
	new_boxes := make(#soa[dynamic]Box, 0, len(boxes))
	defer delete(new_boxes)

	for &box, i in boxes
	{
		populated: bool
		n_count := neighbor_count(boxes, i32(i))

		if box.isfull {
			populated = n_count == 2 || n_count == 3
		} else {
			populated = n_count == 3
		}

		append(&new_boxes, Box{box.x, box.y, populated})
	}

	for box, i in new_boxes {
		if box != boxes[i]
		{
			boxes[i].x = box.x
			boxes[i].y = box.y
			boxes[i].isfull = box.isfull
		}
	}
}

convert_to_f32 :: proc(s: cstring) -> f32
{
	switch s
	{
		case "0.25x":
			return 0.50
		case "0.50x":
			return 0.4375
		case "0.75x":
			return 0.375
		case "1x":
			return 0.3125
		case "1.25x":
			return 0.25
		case "1.50x":
			return 0.1875
		case "1.75x":
			return 0.125
		case "2x":
			return 0.0625
		case:
			return 0
	}
}

speedmenu :: proc(speed: ^f32) -> (mouse_changed: bool = false)
{
	startx := (rl.GetRenderWidth() / 16) * 11
	starty := (rl.GetRenderHeight() / 6)
	width := rl.GetRenderWidth() / 4
	height := (rl.GetRenderHeight() / 3) * 2
	rl.DrawRectangle(startx, starty, width, height, rl.Color{ 126, 186, 230, 255 })
	rl.DrawText("Speed:", startx + 20, starty + 20, 40, rl.Color{ 164, 211, 245, 255 })
	speeds := []cstring{ "0.25x", "0.50x", "0.75x", "1x", "1.25x", "1.50x", "1.75x", "2x" }
	mousex: i32 = rl.GetMouseX()
	mousey: i32 = rl.GetMouseY()
	for speedname, i in speeds
	{
		x := startx + 35
		y := starty + 65 * i32(i) + 65
		w: i32 = 200
		mouse_on_coor := mousex >= x && mousex <= x + w && mousey >= y && mousey <= y + 60
		rl.DrawRectangle(x, y, w, 60, rl.Color{ 164, 211, 245, 255 })
		rl.DrawRectangle(x + 5, y + 5, w - 10, 50, convert_to_f32(speedname) == speed^ || mouse_on_coor ? rl.Color{ 141, 199, 240, 255 } : rl.Color{ 126, 186, 230, 255 })
		rl.DrawText(speedname, x + 10, y + 10, 40, rl.Color{ 164, 211, 245, 255 })
		if mouse_on_coor
		{
			mouse_changed = true
			rl.SetMouseCursor(.POINTING_HAND)
		}

		if rl.IsMouseButtonPressed(.LEFT) && mouse_on_coor
		{
			switch speedname
			{
				case "0.25x":
					speed^ = 0.50
				case "0.50x":
					speed^ = 0.4375
				case "0.75x":
					speed^ = 0.375
				case "1x":
					speed^ = 0.3125
				case "1.25x":
					speed^ = 0.25
				case "1.50x":
					speed^ = 0.1875
				case "1.75x":
					speed^ = 0.125
				case "2x":
					speed^ = 0.0625
			}
		}
	}

	return
}

main :: proc()
{
	sim_on := false
	timer: f32
	is_update_boxes := false
	boxes: #soa[dynamic]Box
	speed: f32 = 0.3125
	defer delete(boxes)

	rl.SetConfigFlags({.FULLSCREEN_MODE})
	rl.InitWindow(1280, 720, "Conway Game of Life")
	rl.SetTargetFPS(60)

	defer rl.CloseWindow()

	for i: i32 = 0; i < VerticalCount; i += 1
	{
		for j: i32 = 0; j < HorizontalCount; j += 1
		{
			append(&boxes, Box{ j, i, false })
		}
	}

	for !rl.WindowShouldClose()
	{
		if rl.IsKeyPressed(.Q)
		{
			break
		}

		defer is_update_boxes = false

		dt := rl.GetFrameTime()
		if sim_on
		{
			timer -= dt
			if timer <= 0
			{
				timer = speed
				is_update_boxes = true
			}
		}

		defer rl.EndDrawing()
		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)
		render(boxes[:])

		mousex: i32 = rl.GetMouseX()
		mousey: i32 = rl.GetMouseY()

		if rl.IsMouseButtonPressed(.LEFT)
		{
			calc_box_pressed(boxes[:], mousex, mousey)
		}

		rect1x := rl.GetRenderWidth() / 2 - ButtonWidth / 2
		rect1y := rl.GetRenderHeight() / 10

		rect2x := rect1x + 5
		rect2y := rect1y + 5

		rl.DrawRectangle(rect1x, rect1y, ButtonWidth, ButtonHeight, rl.Color{ 115, 63, 33, 255 })
		rl.DrawRectangle(rect2x, rect2y, ButtonWidth - 10, ButtonHeight - 10, rl.Color{ 156, 93, 58, 255 })
		if sim_on
		{
			rl.DrawText("Stop Simulation", rect2x + 45, rect2y + 25, 40, rl.WHITE)
		}
		else
		{
			rl.DrawText("Start Simulation", rect2x + 35, rect2y + 25, 40, rl.WHITE)
		}
		mouse_changed := speedmenu(&speed)

		mouse_on_btn := mousex >= rect1x && mousex <= rect1x + ButtonWidth && mousey >= rect1y && mousey <= rect1y + ButtonHeight

		if !mouse_changed && mouse_on_btn
		{
			mouse_changed = true
			rl.SetMouseCursor(.POINTING_HAND)
		}

		if rl.IsMouseButtonPressed(.LEFT) && mouse_on_btn
		{
			sim_on = !sim_on
			if sim_on
			{
				timer = speed
			}
		}

		clearbtnx := rl.GetRenderWidth() / 8
		clearbtny := rl.GetRenderHeight() / 4
		rl.DrawRectangle(clearbtnx, clearbtny, ClearButtonWidth, ClearButtonHeight, rl.Color{ 115, 63, 33, 255 })
		rl.DrawRectangle(clearbtnx + 5, clearbtny + 5, ClearButtonWidth - 10, ClearButtonHeight - 10, rl.Color{ 156, 93, 58, 255 })
		rl.DrawText("Clear", clearbtnx + ClearButtonWidth / 5, clearbtny + ClearButtonHeight / 4, 40, rl.WHITE)

		mouse_on_btn = mousex >= clearbtnx && mousex <= clearbtnx + ClearButtonWidth && mousey >= clearbtny && mousey <= clearbtny + ButtonHeight

		if !mouse_changed && mouse_on_btn
		{
			mouse_changed = true
			rl.SetMouseCursor(.POINTING_HAND)
		}

		if rl.IsMouseButtonPressed(.LEFT) && mouse_on_btn
		{
			for &box in boxes
			{
				box.isfull = false
			}
		}

		nextbtnx := clearbtnx
		nextbtny := clearbtny + ClearButtonHeight + 10
		rl.DrawRectangle(nextbtnx, nextbtny, NextButtonWidth, NextButtonHeight, rl.Color{ 115, 63, 33, 255 })
		rl.DrawRectangle(nextbtnx + 5, nextbtny + 5, NextButtonWidth - 10, NextButtonHeight - 10, rl.Color{ 156, 93, 58, 255 })
		rl.DrawText("Next", nextbtnx + NextButtonWidth / 4, nextbtny + NextButtonHeight / 4, 40, rl.WHITE)

		mouse_on_btn = mousex >= nextbtnx && mousex <= nextbtnx + NextButtonWidth && mousey >= nextbtny && mousey <= nextbtny + NextButtonHeight

		if !mouse_changed && mouse_on_btn
		{
			mouse_changed = true
			rl.SetMouseCursor(.POINTING_HAND)
		}

		if (rl.IsMouseButtonPressed(.LEFT) && mouse_on_btn) || is_update_boxes
		{
			update_boxes(boxes[:])
		}

		if !mouse_changed
		{
			rl.SetMouseCursor(.DEFAULT)
		}
	}
}
