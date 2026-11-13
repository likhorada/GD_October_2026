extends Node

signal master_volume_changed(value: float)
signal locale_changed(locale: String)

const SETTINGS_PATH: String = "user://settings.cfg"
const DEFAULT_MASTER_VOLUME: float = 0.8
const DEFAULT_LOCALE: String = "ru"
const SUPPORTED_LOCALES: PackedStringArray = ["ru", "en"]

var master_volume: float = DEFAULT_MASTER_VOLUME
var locale: String = DEFAULT_LOCALE


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(SETTINGS_PATH)

	if error == OK:
		master_volume = clampf(
			float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)),
			0.0,
			1.0
		)
		locale = str(config.get_value("general", "locale", DEFAULT_LOCALE))

	if locale not in SUPPORTED_LOCALES:
		locale = DEFAULT_LOCALE

	apply_master_volume()
	apply_locale()
	master_volume_changed.emit(master_volume)


func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("general", "locale", locale)

	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings to %s (error %d)." % [SETTINGS_PATH, error])


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_master_volume()
	master_volume_changed.emit(master_volume)
	save_settings()


func set_locale(new_locale: String) -> void:
	if new_locale not in SUPPORTED_LOCALES:
		return

	locale = new_locale
	apply_locale()
	locale_changed.emit(locale)
	save_settings()


func apply_master_volume() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return

	AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))


func apply_locale() -> void:
	TranslationServer.set_locale(locale)
