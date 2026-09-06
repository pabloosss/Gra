extends Node2D
## Low-resolution world rendered to a 768 × 512 SubViewport, then nearest-scaled.
const VIEW_SIZE = Vector2(960,480)
const BUILD_POS = [Vector2(483,314),Vector2(646,297),Vector2(819,305),Vector2(470,430),Vector2(637,439),Vector2(824,430)]
const TREE_POS = Vector2(223,419)
const TREE_RECT = Rect2(139,179,172,242)
var forest = preload("res://assets/forest.png")
var trees = []
var houses = []
var person = []
var font = preload("res://assets/DejaVuSans.ttf")
var time = 0.0
var swing = 0.0
var shake = 0.0
var fall_time = 0.0
var falling_kind = 0
var particles = []
var floats = []
var construction = [0.0,0.0,0.0,0.0,0.0,0.0]
var hover_tree = false
var hover_building = -1
var selected_building = -1
var random = RandomNumberGenerator.new()

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	random.seed = 4217
	for i in range(3): trees.append(load("res://assets/tree_painted_%d.png"%i))
	for i in range(6):
		var row = []
		for l in range(1,4): row.append(load("res://assets/building_%d_%d.png"%[i,l]))
		houses.append(row)
	for i in range(4): person.append(load("res://assets/lumberjack_%d.png"%i))
	State.building_changed.connect(celebrate_build)

func _process(dt):
	time += dt
	swing = maxf(0,swing-dt*5)
	shake = maxf(0,shake-dt*3.7)
	fall_time = maxf(0,fall_time-dt)
	for i in range(6): construction[i] = maxf(0,construction[i]-dt)
	for p in particles:
		p.life -= dt
		p.pos += p.vel*dt
		p.vel.y += dt*160
	particles = particles.filter(func(p): return p.life>0)
	for f in floats:
		f.life -= dt
		f.pos.y -= dt*22
	floats = floats.filter(func(f): return f.life>0)
	queue_redraw()

func hit(data: Dictionary):
	swing = 1.0
	shake = 0.9 if data.critical else 0.55
	for i in range(17 if data.critical else 8):
		particles.append({"pos":Vector2(217,358),"vel":Vector2(random.randf_range(-95,90),random.randf_range(-100,-20)),"life":random.randf_range(0.35,0.75),"color":Color("edbd77") if data.critical else Color("b99569"),"size":Vector2(random.randi_range(2,4),random.randi_range(1,3))})
	floats.append({"pos":Vector2(235,300),"text":("KRYTYK! " if data.critical else "−")+str(int(data.damage)),"life":0.8,"color":Color("f6d192") if data.critical else Color("eee1c5")})
	if data.felled:
		fall_time = 0.65
		falling_kind = State.tree_kind
		floats.append({"pos":Vector2(190,270),"text":"+%s drewna"%format_number(data.reward),"life":1.7,"color":Color("c6e3ad")})
		for i in range(28):
			particles.append({"pos":Vector2(223,397),"vel":Vector2(random.randf_range(-120,120),random.randf_range(-150,-20)),"life":random.randf_range(0.6,1.1),"color":Color("6b845d") if i%2 else Color("b99569"),"size":Vector2(3,3)})

func celebrate_build(id: int, _level: int):
	construction[id] = 1.5
	var p = BUILD_POS[id]
	for i in range(30):
		particles.append({"pos":p+Vector2(random.randf_range(-40,40),-30),"vel":Vector2(random.randf_range(-45,45),random.randf_range(-110,-30)),"life":random.randf_range(.5,1.3),"color":Color("edbd77"),"size":Vector2(2,2)})

func building_at(p: Vector2) -> int:
	for i in range(5,-1,-1):
		if Rect2(BUILD_POS[i]-Vector2(50,98),Vector2(100,122)).has_point(p): return i
	return -1

func _draw():
	draw_texture_rect(forest,Rect2(Vector2.ZERO,VIEW_SIZE),false)
	draw_rect(Rect2(Vector2.ZERO,VIEW_SIZE),Color(0.035,0.09,0.11,0.09))
	# The distant glade opens with the lighthouse.
	if State.buildings[5]>0:
		for i in range(4):
			draw_rect(Rect2(591+i*4,157+i*5,40-i*6,43),Color(0.42,0.7,0.68,0.02))
	# Paths between visible plots are subtle and pixel-aligned.
	for i in range(6):
		var p = BUILD_POS[i]
		if State.buildings[i]==0:
			draw_plot(p,i)
		else:
			if construction[i]>0 and not State.reduced_motion:
				p.y -= abs(sin(construction[i]*10))*construction[i]*2
			draw_texture(houses[i][State.buildings[i]-1],p-Vector2(52,103))
			if i!=3 and not State.reduced_motion:
				for j in range(3):
					var cycle = fmod(time*.25+j*.33,1.0)
					var pp=p+Vector2(22+sin(time+j)*4,-75-State.buildings[i]*5-cycle*31)
					draw_rect(Rect2(pp.floor(),Vector2(5+cycle*5,4+cycle*3).floor()),Color(.65,.69,.65,(1-cycle)*.2))
			if i==5:
				var lamp = p+Vector2(1,-68-State.buildings[i]*9)
				glow(lamp,Color("ffe3a1"),20+State.buildings[i]*9)
			else:
				glow(p+Vector2(-15,-33),Color("f3bd76"),11)
		if i==selected_building or i==hover_building:
			draw_rect(Rect2(p-Vector2(49,8),Vector2(98,28)),Color(.06,.14,.15,.9))
			draw_rect(Rect2(p-Vector2(49,8),Vector2(98,28)),Color("adbd90"),false,1)
		var caption = State.BUILDINGS[i].short
		if State.buildings[i]>0: caption += " "+State.roman(State.buildings[i])
		label_at(p+Vector2(0,10),caption,12,Color("dddbc0") if State.buildings[i]>0 else Color("849388"),true)
	# A lamp by the footpath, a permanent starting camp, and the lumberjack.
	draw_rect(Rect2(93,448,22,3),Color("362f30"))
	draw_rect(Rect2(97,444,16,4),Color("8e6542"))
	var flame_h = 10 if State.reduced_motion else 9+int(sin(time*9)*2)
	draw_rect(Rect2(101,443-flame_h,6,flame_h),Color("d7914e"))
	draw_rect(Rect2(103,439-flame_h/2,3,flame_h/2+5),Color("f2cb85"))
	glow(Vector2(104,440),Color("e9ad60"),27)
	draw_lamp(Vector2(327,390))
	# Tree reaction, respawn, and falling silhouette are independent of production.
	if State.respawn<=0:
		var angle = 0.0 if State.reduced_motion else sin(time*51)*shake*.035
		draw_set_transform(TREE_POS,angle)
		if hover_tree: draw_texture_rect(trees[State.tree_kind],Rect2(-87,-227,174,225),false,Color(1.15,1.2,1.07,0.35))
		draw_texture_rect(trees[State.tree_kind],Rect2(-86,-223,173,221),false)
		draw_set_transform(Vector2.ZERO)
	elif fall_time>0:
		var f = 1-fall_time/.65
		draw_set_transform(TREE_POS,f*.95 if not State.reduced_motion else 0.0)
		draw_texture_rect(trees[falling_kind],Rect2(-86,-223,173,221),false,Color(1,1,1,1-f))
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(213,406,20,10),Color("674b3c"))
		draw_rect(Rect2(213,405,20,3),Color("b49065"))
	var frame = 1+int(swing*2) if swing>0 else int(time*1.6)%2
	var player_pos = Vector2(133,437)
	draw_texture_rect(person[clampi(frame,0,3)],Rect2(player_pos-Vector2(24,58),Vector2(48,58)),false)
	var axe_angle = lerpf(0.75,-1.1,swing) if swing>0 else 0.45
	draw_set_transform(player_pos+Vector2(14,-26),axe_angle)
	draw_rect(Rect2(0,-28,3,31),Color("b29868"))
	draw_polygon(PackedVector2Array([Vector2(2,-27),Vector2(13,-31),Vector2(17,-24),Vector2(13,-19),Vector2(2,-21)]),PackedColorArray([Color("bccdc6")]))
	draw_rect(Rect2(2,-26,3,7),Color("687d80"))
	draw_set_transform(Vector2.ZERO)
	# Workers visibly move between the buildings while producing wood.
	if State.buildings[0]>0:
		for i in range(mini(8,State.worker_count())):
			var x=380+fmod(time*(6+i*2)+i*69,218)
			var y=355+(i%3)*14+sin(time*.7+i)*3
			draw_texture_rect(person[int(time*3+i)%4],Rect2(int(x),int(y),24,29),false,Color(.82,.88,.86))
	# Small, square glows and a slowly shifting band of pixel mist.
	for i in range(18):
		var x = fmod(i*73+time*(1+i%3),920)+20
		var y = 245+fmod(i*41,215)+sin(time*.8+i)*6
		var alpha = .2+maxf(0,sin(time*.7+i))*.55
		draw_rect(Rect2(int(x),int(y),2,2),Color(.76,.85,.57,alpha))
	if not State.reduced_motion:
		for i in range(5):
			var x=fmod(time*3+i*191,1040)-180
			draw_rect(Rect2(int(x),290+i%3*12,150,4),Color(.57,.66,.65,.04))
	if State.boost_left>0:
		glow(Vector2(220,277),Color("9bdebc"),90)
	if State.event_window>0:
		var p=Vector2(320,256+sin(time*2)*7)
		glow(p,Color("9acdc8"),25)
		draw_polygon(PackedVector2Array([p+Vector2(0,-7),p+Vector2(5,0),p+Vector2(0,7),p+Vector2(-5,0)]),PackedColorArray([Color("c8f6dd")]))
	if not State.reduced_motion:
		for p in particles: draw_rect(Rect2(p.pos.floor(),p.size),Color(p.color,clampf(p.life*2,0,1)))
	for f in floats: label_at(f.pos,f.text,13,Color(f.color,minf(1,f.life*2)),true)

func glow(p: Vector2,color: Color,radius: int):
	var flicker = 1.0 if State.reduced_motion else .94+sin(time*4+p.x)*.06
	for i in range(3,0,-1):
		var r = int(radius*i/3.0)
		draw_rect(Rect2(p.floor()-Vector2(r,r*.7),Vector2(r*2,r*1.4)),Color(color,.025*flicker))

func draw_lamp(p: Vector2):
	draw_rect(Rect2(p+Vector2(-2,-44),Vector2(3,44)),Color("735843"))
	draw_rect(Rect2(p+Vector2(-9,-46),Vector2(19,3)),Color("3a3d3b"))
	draw_rect(Rect2(p+Vector2(6,-44),Vector2(2,7)),Color("735843"))
	draw_rect(Rect2(p+Vector2(3,-38),Vector2(9,11)),Color("252f31"))
	draw_rect(Rect2(p+Vector2(5,-36),Vector2(5,7)),Color("f2c780"))
	glow(p+Vector2(7,-32),Color("f2c780"),30)

func draw_plot(p: Vector2,id: int):
	for x in [-32,32]:
		draw_rect(Rect2(p+Vector2(x,-14),Vector2(3,17)),Color("6f6a52"))
		draw_rect(Rect2(p+Vector2(x,-14),Vector2(3,2)),Color("a6966c"))
	for x in range(-30,33,8): draw_rect(Rect2(p+Vector2(x,-6),Vector2(4,1)),Color(.6,.63,.48,.25))
	if State.requirements_met(id):
		label_at(p+Vector2(0,-20),"+",18,Color("a0b08a"),true)

func label_at(p: Vector2,text: String,font_size: int,color: Color,center=false):
	var pos = p.floor()
	if center: pos.x -= floor(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2)
	draw_string(font,pos+Vector2(1,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(.03,.08,.1,.8))
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func format_number(v: float) -> String:
	return ("%.1f"%v).replace(".",",") if v<100 else str(int(v))
