extends Node
var textures:Array[Texture2D]=[
	preload("res://texture/main/gun/1.png"),
	preload("res://texture/main/gun/13.png"),
	preload("res://texture/main/gun/19.png"),
	preload("res://texture/main/gun/34.png"),
	
]
var muzzle:PackedVector2Array=[
	Vector2(11,-4),
	Vector2(19,-1),
	Vector2(42,-1),
	Vector2(28,-3),
]
var names:Array[String]=[
	"沙漠之鹰",
	"P90",
	"巴雷特 XM500",
	"SCAR-L 突击步枪",
]
var handheld_positions:PackedVector2Array=[
	Vector2(32,17),
	Vector2(32,17),
	Vector2(32,17),
	Vector2(32,17),
]
#ms
var shoot_cds:PackedFloat32Array=[
	600,
	110,
	1400,
	180,
]
var damages:PackedFloat32Array=[
	75,
	24.9,
	103.0,
	43.3,
]
var recoil:PackedFloat32Array=[
	75,
	33.0,
	170.0,
	40.0,
]
var shoot_sound:Array[AudioStream]=[
	preload("res://sound/gun/1.mp3"),
	preload("res://sound/gun/13.mp3"),
	preload("res://sound/gun/16.mp3"),
	preload("res://sound/gun/34.mp3"),
	
]
var initial_ammunition_capacity:PackedInt32Array=[
	45,
	250,
	40,
	180,
]

var clip_max_capacity:PackedInt32Array=[
	9,
	40,
	7,
	30,
]
#s
var reload_time:PackedFloat32Array=[
	1.7,
	3.0,
	4.0,
	2.8,
]
#每秒多少像素
var bullet_speeds:PackedFloat32Array=[
	14700.0,
	20000.0,
	90000.0,
	30000.0,
]
#每一毫秒伤害衰减
var damage_decay_rates:PackedFloat32Array=[
	0.03,
	0.02,
	0.006,
	0.017,
]
var reload_sound:Array[AudioStream]=[
	preload("res://sound/gun/reload_1.mp3"),
	preload("res://sound/gun/reload_13.mp3"),
	preload("res://sound/gun/reload_16.mp3"),
	preload("res://sound/gun/reload_34.mp3"),
]
