extends Control

@onready var start_button: Button = $MenuButtons/StartGameButton
@onready var continue_button: Button = $MenuButtons/ContinueButton
@onready var settings_panel: Panel = $SettingsPanel
@onready var credits_panel: Panel = $CreditsPanel
@onready var volume_slider: HSlider = $SettingsPanel/VolumeSlider
@onready var text_speed_slider: HSlider = $SettingsPanel/TextSpeedSlider
@onready var fullscreen_checkbox: CheckBox = $SettingsPanel/FullscreenCheckBox

var game_scene_path = "res://Scenes/MoonLevel.tscn"

func _ready() -> void:
    start_button.pressed.connect(_on_start_game_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    $MenuButtons/SettingsButton.pressed.connect(_on_settings_pressed)
    $MenuButtons/CreditsButton.pressed.connect(_on_credits_pressed)
    $MenuButtons/QuitButton.pressed.connect(_on_quit_pressed)
    $SettingsPanel/CloseButton.pressed.connect(_on_close_settings)
    $SettingsPanel/FullscreenCheckBox.toggled.connect(_on_fullscreen_toggled)
    $SettingsPanel/VolumeSlider.value_changed.connect(_on_volume_changed)
    $SettingsPanel/TextSpeedSlider.value_changed.connect(_on_text_speed_changed)
    $CreditsPanel/CloseButton.pressed.connect(_on_close_credits)
    _update_continue_state()

func _update_continue_state() -> void:
    var save_exists = FileAccess.file_exists("user://sunset_orbit_save.json")
    continue_button.disabled = not save_exists

func _on_start_game_pressed() -> void:
    _clear_save_file()
    get_tree().change_scene_to_file(game_scene_path)

func _on_continue_pressed() -> void:
    get_tree().change_scene_to_file(game_scene_path)

func _on_settings_pressed() -> void:
    settings_panel.visible = true

func _on_close_settings() -> void:
    settings_panel.visible = false

func _on_credits_pressed() -> void:
    credits_panel.visible = true

func _on_close_credits() -> void:
    credits_panel.visible = false

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_fullscreen_toggled(toggled: bool) -> void:
    if toggled:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_changed(value: float) -> void:
    var master_index = AudioServer.get_bus_index("Master")
    AudioServer.set_bus_volume_db(master_index, value)

func _on_text_speed_changed(value: float) -> void:
    ProjectSettings.set_setting("dialogue/text_speed", value)

func _clear_save_file() -> void:
    if FileAccess.file_exists("user://sunset_orbit_save.json"):
        var dir = DirAccess.open("user://")
        if dir:
            dir.remove("sunset_orbit_save.json")
