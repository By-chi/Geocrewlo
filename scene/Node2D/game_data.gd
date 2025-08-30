extends Node
var target_score:=0
var camp_score:Array[int]
var score:Array[Array]
var mortality_database:Array[Array]
func add_elimination_announcement(p1:Entity,p2:Entity)->void:
	var rich:=RichTextLabel.new()
	rich.bbcode_enabled=true
	rich.add_theme_font_size_override("normal_font_size",24)
	var text:String
	var gun_text:String
	if p1.camp==p2.camp:
		text="误伤了"
	else:
		text="击败了"
	if p1.gun!=null:
		gun_text="[color=#8eef97]用\""+GunData.names[p1.gun.id]+"\"[/color]"
	rich.text=(
	"[color=#"+
	p1.self_modulate.to_html(false)+
	"]"+
	p1.name_label.text+
	"[/color]"+
	gun_text+
	"[color=yellow]"+text+"[/color] "+
	"[color=#"+
	p2.self_modulate.to_html(false)+
	"]"+
	p2.name_label.text+
	"[/color]"
	)
	rich.fit_content=true
	#rich.use_parent_material=true
	rich.autowrap_mode=TextServer.AUTOWRAP_OFF
	Global.game_main.UI.elimination_aannouncement.add_child(rich)
	if Global.game_main.UI.elimination_aannouncement.get_child_count()>10:
		Global.game_main.UI.elimination_aannouncement.get_child(0).queue_free()
