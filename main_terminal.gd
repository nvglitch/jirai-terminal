extends Control

var themes = {
	"jirai": {
		"bg": Color("#030004"),
		"text": Color("#ff4fa3"),
		"muted": Color(1.0, 0.31, 0.64, 0.66),
		"green": Color("#00ff66"),
		"yellow": Color("#fff238")
	},
	"mizuiro": {
		"bg": Color("#00070a"),
		"text": Color("#20eaff"),
		"muted": Color(0.12, 0.91, 1.0, 0.66),
		"green": Color("#74ff00"),
		"yellow": Color("#fff238")
	}
}

var current_theme = "jirai"

var history: Array[String] = []
var history_index: int = 0

const completions: Array[String] = [
	"help", "clear", "chuni", "theme", "theme jirai", "theme mizuiro",
	"echo", "date", "whoami", "fortune", "gallery", "maimai"
]

const static_fortunes: Array[String] = [
	"今天的幸运指令是: echo 我已经很努力了",
	"警告: 唐分过高，请及时补充水分。",
	"你的 shell 已经帮你把坏心情放进 /tmp 了。",
	"水色模式适合凌晨，黑粉模式适合发誓重新做人。",
	"今日宜: 摸鱼。忌: 开会。幸运物: 耳机。",
	"运势 ★★★★☆ — 会在地铁上听到一首让你起鸡皮疙瘩的歌。",
	"运势 ★★★★★ — 今天写的 bug 会在三分钟内自己修好。",
	"运势 ★★☆☆☆ — 小心把 rm -rf 打成 rm -rf /，虽然这里不是真 shell。",
	"运势 ★★★☆☆ — 适合喝一杯冰美式然后发呆到下班。",
	"今日幸运字符: 0x7F。它是 DEL，提醒你该删掉一些坏习惯。",
	"运势 ★★★★☆ — 你会发现某个收藏夹里还有三年前存了没看的教程。",
	"运势 ★★★★☆ — 随机播放到一首歌刚好是你一直在找的那首。",
	"运势 ★★★★★ — 今天适合单曲循环一首 city pop。",
	"运势 ★★★☆☆ — 戴耳机的时候注意别把线缠成拓扑学难题。",
	"运势 ★★★★☆ — 你的年度歌单会有一个令人意外但合理的第一名。",
	"运势 ★★☆☆☆ — 不要打舞萌。",
	"今日幸运音符: 440Hz 的 A4。",
	"运势 ★★★☆☆ — 适合用 0.75 倍速重温一首老歌，会有新发现。",
	"运势 ★★★★★ — 今天打音游 AP 概率 +37%，前提是你先活动一下手腕。",
	"运势 ★★★☆☆ — boss 战前记得存档，生活没有 checkpoint。",
	"运势 ★★★★☆ — 你会在匹配到靠谱队友后连赢三把。",
	"运势 ★★☆☆☆ — 抽卡前先洗脸，今天的欧气不太够。",
	"运势 ★★★★☆ — 那个卡关很久的地方，今天再试一次说不定就过了。",
	"今日幸运 combo: 5716。AJ不是梦，只要你相信自己的手。",
	"运势 ★★★☆☆ — 上班摸鱼是一种美德。",
	"运势 ★★★★★ — 今天适合开新档，无论是游戏还是别的什么。"
]

# ---- boot lines 完全对照 index.html ----
const boot_lines = [
	["logo", "     ██╗██╗██████╗  █████╗ ██╗      ██████╗███╗   ███╗██████╗"],
	["logo", "     ██║██║██╔══██╗██╔══██╗██║     ██╔════╝████╗ ████║██╔══██╗"],
	["logo", "     ██║██║██████╔╝███████║██║     ██║     ██╔████╔██║██║  ██║"],
	["logo", "██   ██║██║██╔══██╗██╔══██║██║     ██║     ██║╚██╔╝██║██║  ██║"],
	["logo", "╚█████╔╝██║██║  ██║██║  ██║██║     ╚██████╗██║ ╚═╝ ██║██████╔╝"],
	["logo", " ╚════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝╚═╝     ╚═╝╚═════╝"],
	["system", ""],
	["system", "jirai-cmd v0.6.16 booting..."],
	["ok", "fullscreen tty ............. ok"],
	["ok", "loading png-ascii idol ...... ok"],
	["ok", "mounting heart:/var/fragile . ok"],
	["response", "欢迎来到 jirai-cmd。输入 help 查看可用命令。"]
]

@onready var lines_container = $TerminalViewport/MarginWrap/OutputWrap/LinesContainer
@onready var input_area = $TerminalViewport/MarginWrap/OutputWrap/LinesContainer/InputArea
@onready var command_input = $TerminalViewport/MarginWrap/OutputWrap/LinesContainer/InputArea/CommandInput
@onready var scroll_wrap = $TerminalViewport/MarginWrap/OutputWrap
@onready var background = $Background
@onready var clock_label = $TerminalViewport/MetaBarMargin/MetaBar/ClockLabel
@onready var hint_label = $TerminalViewport/MetaBarMargin/MetaBar/HintLabel
@onready var btn_jirai = $ThemeSwitch/BtnJirai
@onready var btn_mizuiro = $ThemeSwitch/BtnMizuiro
@onready var char_image = $CharImage
@onready var prompt_label = $TerminalViewport/MarginWrap/OutputWrap/LinesContainer/InputArea/Prompt

# 自定义块状光标
var cursor_rect: ColorRect = null
var cursor_blink_tween: Tween = null
@onready var terminal_border = $TerminalBorder

var gallery_scene: PackedScene = preload("res://gallery.tscn")
var gallery_instance: Control = null

const CONFIG_PATH = "user://jirai_terminal.cfg"

func _ready():
	command_input.text_submitted.connect(_on_text_submitted)
	command_input.text_changed.connect(func(_t): _update_cursor_pos())
	btn_jirai.pressed.connect(func(): apply_theme("jirai"); command_input.grab_focus())
	btn_mizuiro.pressed.connect(func(): apply_theme("mizuiro"); command_input.grab_focus())
	# 隐藏默认光标，用自定义块状光标
	command_input.caret_blink = false
	command_input.caret_force_displayed = false
	_setup_cursor()
	
	var saved_theme = load_theme_config()
	apply_theme(saved_theme)
	
	# 完全对照网页版 bootLines
	for line in boot_lines:
		append_line(line[0], line[1])
	
	command_input.grab_focus()

func _setup_cursor():
	cursor_rect = ColorRect.new()
	cursor_rect.size = Vector2(8, 18)
	cursor_rect.color = Color.WHITE
	cursor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_area.add_child(cursor_rect)
	_blink_cursor()

func _blink_cursor():
	if not is_instance_valid(cursor_rect): return
	if cursor_blink_tween and cursor_blink_tween.is_valid():
		cursor_blink_tween.kill()
	cursor_blink_tween = create_tween().set_loops()
	cursor_blink_tween.tween_property(cursor_rect, "modulate:a", 1.0, 0.01)
	cursor_blink_tween.tween_interval(0.53)
	cursor_blink_tween.tween_property(cursor_rect, "modulate:a", 0.0, 0.01)
	cursor_blink_tween.tween_interval(0.53)

func _update_cursor_pos():
	if not is_instance_valid(cursor_rect) or not is_instance_valid(prompt_label): return
	var text_before = command_input.text.substr(0, command_input.caret_column)
	var x_off = 0.0
	var font = command_input.get_theme_font("font")
	if font and text_before != "":
		var sz = font.get_string_size(text_before, HORIZONTAL_ALIGNMENT_LEFT, -1, command_input.get_theme_font_size("font_size"))
		x_off = sz.x
	cursor_rect.position.x = prompt_label.size.x + 4 + x_off
	cursor_rect.position.y = (input_area.size.y - cursor_rect.size.y) / 2
	cursor_rect.color = themes[current_theme]["text"]

func _process(_delta):
	var dt = Time.get_datetime_dict_from_system()
	clock_label.text = "%04d/%02d/%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
	# 持续更新光标位置 (处理窗口 resize 等)
	if command_input.has_focus():
		_update_cursor_pos()

func _update_hint():
	var th = themes[current_theme]
	var alt = "mizuiro" if current_theme == "jirai" else "jirai"
	# 对照网页版: 不同命令用不同颜色
	hint_label.clear()
	hint_label.push_color(th["yellow"]); hint_label.append_text("try: ")
	hint_label.push_color(th["text"]);   hint_label.append_text("help")
	hint_label.pop(); hint_label.append_text(" / ")
	hint_label.push_color(th["green"]);  hint_label.append_text("theme " + alt)
	hint_label.pop(); hint_label.append_text(" / ")
	hint_label.push_color(Color("#ff305f")); hint_label.append_text("echo 好想睡觉")
	hint_label.pop(); hint_label.append_text(" / ")
	hint_label.push_color(th["text"]);   hint_label.append_text("fortune")
	hint_label.pop(); hint_label.append_text(" / ")
	hint_label.push_color(th["text"]);   hint_label.append_text("clear")

func append_line(kind: String, text: String):
	var label = Label.new()
	label.text = text
	label.set_meta("kind", kind)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_FILL
	match kind:
		"logo":
			label.modulate = themes[current_theme]["text"] * 1.5
		"system":
			label.text = "■ " + text
			label.modulate = themes[current_theme]["muted"]
		"ok":
			label.modulate = themes[current_theme]["green"]
		"response":
			label.text = "▶ " + text
			label.modulate = themes[current_theme]["text"]
		"command":
			label.text = "maid@jirai:~$ " + text
			label.modulate = themes[current_theme]["text"]
		"error":
			label.text = "!! " + text
			label.modulate = Color(2.5, 0.2, 0.4)
		"warn":
			label.modulate = themes[current_theme]["yellow"]
		"info":
			label.modulate = Color("#38a0ff")
	lines_container.add_child(label)
	lines_container.move_child(label, input_area.get_index())
	# 延迟滚动，不用 await 避免打断焦点
	call_deferred("_scroll_to_input")

func _scroll_to_input():
	if is_instance_valid(scroll_wrap) and is_instance_valid(input_area):
		scroll_wrap.ensure_control_visible(input_area)

func _on_text_submitted(new_text: String):
	var cmd = new_text.strip_edges()
	if cmd == "": return
	
	append_line("command", cmd)
	history.append(cmd)
	history_index = history.size()
	command_input.text = ""
	
	var parts = cmd.split(" ")
	var base_cmd = parts[0].to_lower()
	var rest = cmd.substr(base_cmd.length()).strip_edges()
	
	match base_cmd:
		"help":
			append_line("response", "可用命令:")
			append_line("response", "  help                 显示帮助")
			append_line("response", "  clear                清空屏幕")
			append_line("response", "  theme                查看当前皮肤")
			append_line("response", "  theme jirai          切换黑粉皮肤")
			append_line("response", "  theme mizuiro        切换水色皮肤")
			append_line("response", "  echo <text>          输出一段文字")
			append_line("response", "  date                 显示当前时间")
			append_line("response", "  whoami               查看当前用户")
			append_line("response", "  fortune              抽一条今日终端签")
			append_line("response", "  maimai               查看 maimai DX b50")
			append_line("response", "  chuni                查看 CHUNITHM b30")
			append_line("response", "  gallery              浏览 photo 画廊")
		"clear":
			for child in lines_container.get_children():
				if child != input_area:
					child.queue_free()
		"date":
			append_line("system", Time.get_datetime_string_from_system(false, true))
		"echo":
			append_line("response", rest)
		"whoami":
			enter_yandere_mode()
		"maimai":
			cmd_maimai()
		"chuni":
			cmd_chuni()
		"gallery":
			cmd_gallery(parts.slice(1))
		"fortune":
			var d = Time.get_date_dict_from_system()
			var seed_str = "%04d-%02d-%02d" % [d.year, d.month, d.day]
			var h = 0
			for c in seed_str:
				h = ((h << 5) - h + c.unicode_at(0)) & 0xFFFFFFFF
			h = abs(h)
			var idx = h % (static_fortunes.size() + 1)
			if idx < static_fortunes.size():
				append_line("warn", static_fortunes[idx])
			else:
				append_line("warn", "今日推荐 BPM: %d。太快会喘，太慢会困。" % (100 + (h ^ 0x626D70) % 80))
		"theme":
			if parts.size() > 1 and themes.has(parts[1]):
				apply_theme(parts[1])
				append_line("ok", "skin loaded: " + parts[1])
			elif parts.size() == 1:
				append_line("response", "当前皮肤: " + current_theme)
			else:
				append_line("error", "找不到这个皮肤。可选: jirai, mizuiro")
		_:
			append_line("error", base_cmd + ": command not found. 输入 help 看看菜单。")
	
	# 同步抓焦点（不再用 call_deferred，append_line 已无 await）
	command_input.grab_focus()
	_update_cursor_pos()

func _unhandled_key_input(event: InputEvent):
	if not event is InputEventKey or not event.pressed: return
	
	# 画廊选择模式优先
	if gallery_select_active:
		match event.keycode:
			KEY_UP:
				gallery_select_index = max(0, gallery_select_index - 1)
				_update_gallery_cursor(); get_viewport().set_input_as_handled(); return
			KEY_DOWN:
				gallery_select_index = min(gallery_lines.size() - 1, gallery_select_index + 1)
				_update_gallery_cursor(); get_viewport().set_input_as_handled(); return
			KEY_ENTER, KEY_KP_ENTER:
				var idx = gallery_select_index; _exit_gallery_select(); open_gallery(idx)
				get_viewport().set_input_as_handled(); return
			KEY_ESCAPE:
				_exit_gallery_select(); get_viewport().set_input_as_handled(); return
			_:
				_exit_gallery_select()
	
	if not command_input.has_focus(): return
	
	match event.keycode:
		KEY_UP:
			history_index = max(0, history_index - 1)
			command_input.text = history[history_index] if history_index < history.size() else ""
			command_input.caret_column = command_input.text.length()
			_update_cursor_pos()
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			history_index = min(history.size(), history_index + 1)
			command_input.text = history[history_index] if history_index < history.size() else ""
			command_input.caret_column = command_input.text.length()
			_update_cursor_pos()
			get_viewport().set_input_as_handled()
		KEY_TAB:
			var val = command_input.text
			if val != "":
				for c in completions:
					if c.begins_with(val) and c != val:
						command_input.text = c
						command_input.caret_column = c.length()
						_update_cursor_pos()
						break
			get_viewport().set_input_as_handled()

# ---- maimai / chuni ----
var _maimai_data_cache: Array = []
var _chuni_data_cache: Array = []
var _data_loaded := false

func _ensure_data_loaded():
	if _data_loaded: return
	_data_loaded = true
	var f = FileAccess.open("res://maimai_data.json", FileAccess.READ)
	if f: var p = JSON.parse_string(f.get_as_text()); if p is Array: _maimai_data_cache = p; f.close()
	f = FileAccess.open("res://chuni_data.json", FileAccess.READ)
	if f: var p = JSON.parse_string(f.get_as_text()); if p is Array: _chuni_data_cache = p; f.close()

func _b50(rows: Array) -> Array:
	var best := {}
	for r in rows:
		var rt = float(r.get("dx_rating", 0))
		if rt <= 0: continue
		var k = str(r.get("song_name","")) + "|" + str(r.get("level_index","3"))
		if not best.has(k) or rt > best[k].get("_r",0.0):
			var e = r.duplicate(); e["_r"] = rt; best[k] = e
	var s: Array = []; s.assign(best.values()); s.sort_custom(func(a,b): return a["_r"] > b["_r"]); return s.slice(0, 50)

func _b30(rows: Array) -> Array:
	var best := {}
	for r in rows:
		var rt = float(r.get("rating", 0))
		if rt <= 0: continue
		var k = str(r.get("song_name","")) + "|" + str(r.get("level_index","3"))
		if not best.has(k) or rt > best[k].get("_r",0.0):
			var e = r.duplicate(); e["_r"] = rt; best[k] = e
	var s: Array = []; s.assign(best.values()); s.sort_custom(func(a,b): return a["_r"] > b["_r"]); return s.slice(0, 30)

func cmd_maimai():
	_ensure_data_loaded()
	if _maimai_data_cache.is_empty(): append_line("error", "无法加载 maimai 数据"); return
	var top = _b50(_maimai_data_cache)
	var total: float = 0.0; for r in top: total += r["_r"]
	append_line("response", "🎧 maimai DX b50 — %d 曲  total: %.0f" % [top.size(), total])
	append_line("system", "  #  rating  lv    achv      song")
	for i in top.size():
		var r = top[i]
		append_line("info", " %s %s %s %s  %s" % [str(i+1).lpad(3), str(int(r["_r"])).lpad(6), str(r.get("level","")).lpad(5), str(r.get("achievements","")).lpad(8), r.get("song_name","")])
	append_line("system", "total: %.0f  |  avg: %.0f" % [total, total / top.size()])

func cmd_chuni():
	_ensure_data_loaded()
	if _chuni_data_cache.is_empty(): append_line("error", "无法加载 CHUNITHM 数据"); return
	var top = _b30(_chuni_data_cache)
	var total: float = 0.0; for r in top: total += r["_r"]
	append_line("response", "🎹 CHUNITHM b30 — %d 曲  total: %.2f" % [top.size(), total])
	append_line("system", "  #  rating   lv    score      song")
	for i in top.size():
		var r = top[i]
		append_line("info", " %s %s %s %s  %s" % [str(i+1).lpad(3), str("%.2f" % r["_r"]).lpad(7), str(r.get("level","")).lpad(5), str(r.get("score","")).lpad(8), r.get("song_name","")])
	append_line("system", "total: %.2f  |  avg: %.2f" % [total, total / top.size()])

# ---- gallery ----
const photos: Array[String] = [
	"res://jiraicmd/photo/huaban-5891557590.png",
	"res://jiraicmd/photo/huaban-7043666532.jpg",
	"res://jiraicmd/photo/huaban-7044481957.jpg",
	"res://jiraicmd/photo/huaban-7046974279.jpg",
	"res://jiraicmd/photo/huaban-7046977964.jpg",
	"res://jiraicmd/photo/huaban-7051791986.jpg",
	"res://jiraicmd/photo/huaban-7158846051.jpg",
	"res://jiraicmd/photo/huaban-7171145595.jpg",
]
var gallery_index: int = 0
var gallery_select_active: bool = false
var gallery_select_index: int = 0
var gallery_lines: Array = []

func open_gallery(index: int = 0):
	if gallery_instance: close_gallery()
	gallery_instance = gallery_scene.instantiate()
	gallery_instance.name = "GalleryOverlay"
	add_child(gallery_instance)
	var bp = gallery_instance.get_node("GalleryFrame/GalleryControls/BtnPrev")
	var bc = gallery_instance.get_node("GalleryFrame/GalleryControls/BtnClose")
	var bn = gallery_instance.get_node("GalleryFrame/GalleryControls/BtnNext")
	bp.pressed.connect(gallery_prev); bc.pressed.connect(close_gallery); bn.pressed.connect(gallery_next)
	gallery_instance.gui_input.connect(_on_gallery_overlay_input)
	gallery_index = clampi(index, 0, photos.size() - 1)
	show_photo(gallery_index)
	command_input.release_focus()

func close_gallery():
	if not gallery_instance: return
	gallery_instance.queue_free(); gallery_instance = null
	for l in gallery_lines: if is_instance_valid(l): l.queue_free()
	gallery_lines.clear(); gallery_select_active = false
	command_input.grab_focus()
	_update_cursor_pos()

func show_photo(i: int):
	if not gallery_instance: return
	gallery_index = i
	var img = gallery_instance.get_node("GalleryFrame/GalleryImage") as TextureRect; img.texture = null
	var path = photos[i]
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex: img.texture = tex
	(gallery_instance.get_node("GalleryFrame/GalleryHeader/GalleryFilename") as Label).text = path.get_file()
	(gallery_instance.get_node("GalleryFrame/GalleryHeader/GalleryCounter") as Label).text = "[%d/%d]" % [i+1, photos.size()]

func gallery_next(): show_photo((gallery_index + 1) % photos.size())
func gallery_prev(): show_photo((gallery_index - 1 + photos.size()) % photos.size())

func _on_gallery_overlay_input(event: InputEvent):
	if not gallery_instance: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE: close_gallery(); get_viewport().set_input_as_handled()
			KEY_LEFT: gallery_prev(); get_viewport().set_input_as_handled()
			KEY_RIGHT: gallery_next(); get_viewport().set_input_as_handled()

func cmd_gallery(args: Array):
	var idx = -1
	if args.size() > 0 and args[0].is_valid_int(): idx = int(args[0])
	if idx >= 0 and idx < photos.size():
		append_line("ok", "opening %s ..." % photos[idx].get_file()); open_gallery(idx)
	elif args.size() > 0 and (idx < 0 or idx >= photos.size()):
		append_line("error", "编号 %d 不存在，共 %d 张 (0-%d)" % [idx, photos.size(), photos.size()-1])
	else:
		append_line("response", "📁 photo/ — %d 张图片 (↑↓ 移动 Enter 打开 Esc 取消)" % photos.size())
		gallery_lines.clear()
		for i in photos.size():
			var label = Label.new()
			label.text = "    [%d] %s" % [i, photos[i].get_file()]
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_FILL
			label.modulate = Color("#38a0ff")
			lines_container.add_child(label); lines_container.move_child(label, input_area.get_index())
			gallery_lines.append(label)
		gallery_select_index = 0; gallery_select_active = true; _update_gallery_cursor()
		call_deferred("_scroll_to_input")

func _update_gallery_cursor():
	for i in gallery_lines.size():
		var l = gallery_lines[i]
		if i == gallery_select_index:
			l.text = " ▶ [%d] %s" % [i, photos[i].get_file()]; l.modulate = Color("#ff4fa3")
		else:
			l.text = "    [%d] %s" % [i, photos[i].get_file()]; l.modulate = Color("#38a0ff")

func _exit_gallery_select():
	gallery_select_active = false
	for l in gallery_lines: if is_instance_valid(l): l.queue_free()
	gallery_lines.clear()

# ---- yandere mode (直接用代码创建，避免场景文件问题) ----
var yandere_wall: ColorRect = null
var yandere_active: bool = false
var yandere_timers: Array = []
const yandere_phrases: Array[String] = ["你是我的唯一"]

func enter_yandere_mode():
	if yandere_active: return
	yandere_active = true
	
	# 直接用代码创建全屏黑色遮罩
	yandere_wall = ColorRect.new()
	yandere_wall.name = "YandereWall"
	yandere_wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	yandere_wall.color = Color.BLACK
	yandere_wall.mouse_filter = Control.MOUSE_FILTER_STOP
	yandere_wall.gui_input.connect(_on_yandere_input)
	add_child(yandere_wall)
	
	command_input.release_focus()
	
	var vs = get_viewport().get_visible_rect().size
	_spawn_yandere_batch(0, 160, 5, vs)

func _spawn_yandere_batch(spawned: int, max_count: int, batch: int, screen_size: Vector2):
	if not yandere_active or spawned >= max_count or not is_instance_valid(yandere_wall): return
	var limit = mini(spawned + batch, max_count)
	for i in range(spawned, limit):
		var label = Label.new()
		label.text = yandere_phrases[randi() % yandere_phrases.size()]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(randf_range(-0.05, 1.05) * screen_size.x, randf_range(-0.05, 1.05) * screen_size.y)
		var fs = randi_range(13, 35)
		label.add_theme_font_size_override("font_size", fs)
		label.rotation = deg_to_rad(randf_range(-10, 10))
		if fs > 18: label.add_theme_font_override("font", load("res://CascadiaMono.ttf"))
		# 红色文字，直接可见（不延迟淡入，避免 Tween 在复杂场景中失败）
		label.modulate = Color(1, 0.19, 0.37, randf_range(0.45, 0.9))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		yandere_wall.add_child(label)
		_start_yandere_flicker(label)
	
	var next_spawned = limit
	# 4 阶段间隔
	var interval: float = 0.25
	if next_spawned <= 40: interval = 0.025
	elif next_spawned <= 90: interval = 0.05
	elif next_spawned <= 130: interval = 0.1
	
	var timer = get_tree().create_timer(interval + randf_range(0, 0.03))
	timer.timeout.connect(func(): _spawn_yandere_batch(next_spawned, max_count, batch, screen_size))
	yandere_timers.append(timer)

func _start_yandere_flicker(label: Label):
	if not yandere_active or not is_instance_valid(label): return
	var tween = create_tween().set_loops()
	tween.tween_property(label, "modulate:a", label.modulate.a * 0.55, 0.6)
	tween.tween_property(label, "modulate:a", label.modulate.a * 1.15, 0.15)
	tween.tween_property(label, "modulate:a", label.modulate.a * 0.65, 0.4)
	tween.tween_property(label, "modulate:a", label.modulate.a * 1.0, 0.6)

func exit_yandere_mode():
	yandere_active = false
	for t in yandere_timers:
		if is_instance_valid(t): t.timeout.disconnect(_spawn_yandere_batch)
	yandere_timers.clear()
	if is_instance_valid(yandere_wall):
		yandere_wall.queue_free(); yandere_wall = null
	command_input.grab_focus()
	_update_cursor_pos()

func _on_yandere_input(event: InputEvent):
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		exit_yandere_mode()

# ---- 主题 ----
func apply_theme(theme_name: String):
	current_theme = theme_name
	background.color = themes[theme_name]["bg"]
	$TerminalViewport/MarginWrap/OutputWrap/LinesContainer/InputArea/Prompt.modulate = themes[theme_name]["yellow"]
	command_input.add_theme_color_override("font_color", themes[theme_name]["text"])
	btn_jirai.button_pressed = (theme_name == "jirai")
	btn_mizuiro.button_pressed = (theme_name == "mizuiro")
	# 角色立绘 (主题切换时换图)
	_update_char_image(theme_name)
	# 光标颜色
	if is_instance_valid(cursor_rect):
		cursor_rect.color = themes[theme_name]["text"]
	# 时钟颜色跟随主题
	clock_label.modulate = themes[theme_name]["text"]
	# 边框
	var bs = terminal_border.get_theme_stylebox("panel", "Panel")
	if bs is StyleBoxFlat: bs.border_color = themes[theme_name]["muted"]
	# 遍历刷新所有已输出的行
	_refresh_all_lines(theme_name)
	# 刷新 hint 颜色
	_update_hint()
	save_theme_config(theme_name)

func _refresh_all_lines(theme_name: String):
	var th = themes[theme_name]
	for child in lines_container.get_children():
		if not child is Label or not child.has_meta("kind"): continue
		var kind = child.get_meta("kind")
		match kind:
			"logo":     child.modulate = th["text"] * 1.5
			"system":   child.modulate = th["muted"]
			"ok":       child.modulate = th["green"]
			"response": child.modulate = th["text"]
			"command":  child.modulate = th["text"]
			"warn":     child.modulate = th["yellow"]
			# error / info 不依赖主题色，跳过

func save_theme_config(theme_name: String):
	var cfg = ConfigFile.new(); cfg.set_value("theme", "name", theme_name); cfg.save(CONFIG_PATH)

func load_theme_config() -> String:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK: return cfg.get_value("theme", "name", "jirai")
	return "jirai"

func _update_char_image(theme_name: String):
	var path = "res://char_pink.png" if theme_name == "jirai" else "res://char_mizuiro.png"
	char_image.texture = load(path)
	# 统一宽度 610，高度按比例；统一 offset_top 让两张图顶部对齐
	if char_image.texture:
		var tw = char_image.texture.get_width()
		var th = char_image.texture.get_height()
		var target_w = 610
		var target_h = int(target_w * float(th) / float(tw))
		# 取较大高度固定顶部位置，避免一个高一个低
		var max_h = int(target_w * max(565.0/782.0, 600.0/766.0))  # ~478
		char_image.offset_top = -(max_h + 48)
		char_image.offset_bottom = -48
		char_image.offset_left = -(target_w + 18)
		char_image.offset_right = -18
		$TerminalViewport/MarginWrap.add_theme_constant_override("margin_right", target_w + 30)
