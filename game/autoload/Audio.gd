extends Node
## Simple BGM / SFX manager. Gracefully ignores missing audio files so the
## game still runs before real (AI-generated) assets are dropped in.

const BGM_DIR := "res://assets/music/"
const SFX_DIR := "res://assets/music/" # sfx live alongside music for now

var _bgm: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _current_bgm: String = ""


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Master"
	add_child(_bgm)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "Master"
	add_child(_sfx)
	apply_volumes()


func apply_volumes() -> void:
	if _bgm:
		_bgm.volume_db = linear_to_db(clampf(GameState.settings.get("bgm_volume", 0.8), 0.0, 1.0))
	if _sfx:
		_sfx.volume_db = linear_to_db(clampf(GameState.settings.get("sfx_volume", 0.9), 0.0, 1.0))


func play_bgm(track: String) -> void:
	if track == _current_bgm:
		return
	_current_bgm = track
	var stream := _load_stream(BGM_DIR + track)
	if stream == null:
		_bgm.stop()
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	_bgm.stream = stream
	_bgm.play()


func stop_bgm() -> void:
	_current_bgm = ""
	_bgm.stop()


func play_sfx(name: String) -> void:
	var stream := _load_stream(SFX_DIR + name)
	if stream:
		_sfx.stream = stream
		_sfx.play()


func _load_stream(base_path: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		var p: String = base_path + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null
