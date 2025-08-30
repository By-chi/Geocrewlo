extends Node
const textures:Array[Texture2D]=[
	preload("res://texture/main/gun/1.png"),
	preload("res://texture/main/gun/13.png"),
	preload("res://texture/main/gun/19.png"),
	preload("res://texture/main/gun/34.png"),
	preload("res://texture/main/gun/39.png"),
	
]
const muzzle:PackedVector2Array=[
	Vector2(11,-4),
	Vector2(19,-1),
	Vector2(42,-1),
	Vector2(28,-3),
	Vector2(30,-4),
]
const names:Array[String]=[
	"沙漠之鹰",
	"P90",
	"巴雷特 XM500",
	"SCAR-L 突击步枪",
	"伯莱塔 SO10 Field",
]
const handheld_positions:PackedVector2Array=[
	Vector2(32,17),
	Vector2(32,17),
	Vector2(32,17),
	Vector2(32,17),
	Vector2(35,20),
]
#ms 射速间隔（数值越小射速越快）
const shoot_cds:PackedFloat32Array=[
	600,
	110,
	1900,
	160,
	250,
]
const damages:PackedFloat32Array=[
	72,
	23.5,
	115.0,
	47.0,
	17.2,
]
const recoil:PackedFloat32Array=[
	90,
	25.0,
	220.0,
	35.0,
	75.0,
]
const shoot_sound:Array[AudioStream]=[
	preload("res://sound/gun/1.mp3"),
	preload("res://sound/gun/13.mp3"),
	preload("res://sound/gun/16.mp3"),
	preload("res://sound/gun/34.mp3"),
	preload("res://sound/gun/39.mp3"),
]
const initial_ammunition_capacity:PackedInt32Array=[
	36,
	350,
	25,
	240,
	45
]

const clip_max_capacity:PackedInt32Array=[
	7,
	55,
	5,
	30,
	6
]
#s 换弹时间
const reload_time:PackedFloat32Array=[
	1.2,
	2.8,
	3.6,
	2.0,
	2.8,
]
#每秒多少像素 子弹飞行速度
const bullet_speeds:PackedFloat32Array=[
	16000.0,
	22000.0,
	70000.0,
	35000.0,
	10000.0
]
#每一毫秒伤害衰减
const damage_decay_rates:PackedFloat32Array=[
	0.025,
	0.02,
	0.002,
	0.014,
	0.035
]
const reload_sound:Array[AudioStream]=[
	preload("res://sound/gun/reload_1.mp3"),
	preload("res://sound/gun/reload_13.mp3"),
	preload("res://sound/gun/reload_16.mp3"),
	preload("res://sound/gun/reload_34.mp3"),
	preload("res://sound/gun/reload_39.mp3"),
]
const pellets_number:PackedInt32Array=[
	1,
	1,
	1,
	1,
	9,
]
# 基础散布角度（弧度）
const base_spread_angle:PackedFloat32Array=[
	0.028,
	0.032,
	0.004,
	0.011,
	0.13
]

# 连射散布增幅（弧度/发）
const burst_spread_increment:PackedFloat32Array=[
	0.038,
	0.007,
	0.15,
	0.011,
	0.0,
]
