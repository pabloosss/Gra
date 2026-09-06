extends Control
var kind = 0
var tint = Color("e1b978")

func _ready():
	custom_minimum_size=Vector2(34,34)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw():
	var p=(size-Vector2(28,28))/2
	draw_set_transform(p)
	match kind:
		0:
			for y in [4,12,20]:
				draw_rect(Rect2(3,y,20,5),Color("997249"));draw_rect(Rect2(3,y,20,1),Color("d5b480"));draw_rect(Rect2(23,y-1,4,7),Color("c69c67"));draw_rect(Rect2(24,y+1,2,3),Color("76563c"))
		1:
			draw_rect(Rect2(7,4,14,22),tint);draw_rect(Rect2(3,8,22,14),tint);draw_rect(Rect2(7,8,14,14),Color("af8048"));draw_rect(Rect2(12,10,4,11),tint);draw_rect(Rect2(9,12,10,3),tint)
		2:
			draw_line(Vector2(5,26),Vector2(20,5),Color("b59865"),4);draw_polygon(PackedVector2Array([Vector2(15,7),Vector2(23,2),Vector2(28,7),Vector2(24,16),Vector2(17,13)]),PackedColorArray([Color("b6c9c0")]))
		3:
			draw_rect(Rect2(5,15,20,11),Color("68967e"));draw_polygon(PackedVector2Array([Vector2(2,15),Vector2(15,3),Vector2(28,15)]),PackedColorArray([Color("92b69b")]));draw_rect(Rect2(12,18,5,8),Color("e6ba76"))
		4:
			draw_rect(Rect2(12,4,4,21),tint);draw_line(Vector2(5,11),Vector2(23,19),tint,3);draw_line(Vector2(5,19),Vector2(23,11),tint,3)
		_:
			draw_rect(Rect2(5,7,18,18),Color("658276"));draw_rect(Rect2(8,4,18,18),Color("c1bb98"));draw_rect(Rect2(12,9,10,2),Color("5b736a"));draw_rect(Rect2(12,14,8,2),Color("5b736a"))
