extends Node2D

const DATA_PATH = "res://Data/nasa_discoveries.json"
const SAVE_PATH = "user://sunset_orbit_save.json"

@onready var player: CharacterBody2D = $Player
@onready var objective_label: Label = $CanvasLayer/HUD/ObjectiveLabel
@onready var signal_label: Label = $CanvasLayer/HUD/SignalLabel
@onready var discovery_counter: Label = $CanvasLayer/HUD/DiscoveryCounter
@onready var interaction_prompt: Label = $CanvasLayer/HUD/InteractionPrompt
@onready var mission_control_box: Label = $CanvasLayer/HUD/MissionControlBox/MissionControlLabel
@onready var discovery_panel: Panel = $CanvasLayer/HUD/DiscoveryPanel
@onready var discovery_title: Label = $CanvasLayer/HUD/DiscoveryPanel/TitleLabel
@onready var discovery_meta: Label = $CanvasLayer/HUD/DiscoveryPanel/MetaLabel
@onready var discovery_description: Label = $CanvasLayer/HUD/DiscoveryPanel/DescriptionLabel
@onready var challenge_label: Label = $CanvasLayer/HUD/DiscoveryPanel/ChallengeLabel
@onready var answer_buttons_container: VBoxContainer = $CanvasLayer/HUD/DiscoveryPanel/AnswerButtons
@onready var transition_panel: Panel = $CanvasLayer/HUD/TransitionPanel
@onready var transition_text: Label = $CanvasLayer/HUD/TransitionPanel/Text

var discovery_data: Array = []
var discovered_ids: Array = []
var markers: Dictionary = {}
var active_marker: Node2D = null
var current_answer_buttons: Array = []
var current_discovery_id: String = ""

func _ready() -> void:
    _load_discovery_data()
    _load_save_state()
    _register_markers()
    _update_hud()
    _set_message("Mission Control: The signal is repeating across the lunar dark. The archive is still incomplete.")

func _process(_delta: float) -> void:
    _poll_interactions()

func _register_markers() -> void:
    markers["apollo_lunar_module"] = $LunarModuleMarker
    markers["apollo_lunar_retroreflector"] = $RetroreflectorMarker
    markers["apollo_alsep"] = $ALSEPMarker

    for key in markers.keys():
        if discovered_ids.has(key):
            markers[key].visible = false

func _load_discovery_data() -> void:
    var file = FileAccess.open(DATA_PATH, FileAccess.READ)
    if file == null:
        return
    var json = JSON.new()
    var parse_error = json.parse(file.get_as_text())
    if parse_error != OK:
        return
    var result = json.data
    if typeof(result) == TYPE_DICTIONARY and result.has("discoveries"):
        discovery_data = result["discoveries"]

func _load_save_state() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var json = JSON.new()
    var parse_error = json.parse(file.get_as_text())
    if parse_error != OK:
        return
    var data = json.data
    if typeof(data) == TYPE_DICTIONARY and data.has("discovered"):
        discovered_ids = data["discovered"]

func _save_state() -> void:
    var save_data = {"discovered": discovered_ids}
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(save_data))
        file.close()

func _poll_interactions() -> void:
    if discovery_panel.visible:
        return

    var nearest_marker = null
    var nearest_distance = 9999.0

    for key in markers.keys():
        if discovered_ids.has(key):
            continue
        var marker = markers[key]
        if not marker.visible:
            continue
        var distance = player.global_position.distance_to(marker.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest_marker = marker

    if nearest_marker != null && nearest_distance < 110.0:
        active_marker = nearest_marker
        interaction_prompt.visible = true
        interaction_prompt.text = "Press E to inspect " + nearest_marker.get_meta("title", "artifact")
        if Input.is_key_pressed(KEY_E):
            _open_discovery_for_marker(nearest_marker)
    else:
        active_marker = null
        interaction_prompt.visible = false

func _open_discovery_for_marker(marker: Node2D) -> void:
    var discovery_id = ""
    if marker == $LunarModuleMarker:
        discovery_id = "apollo_lunar_module"
    elif marker == $RetroreflectorMarker:
        discovery_id = "apollo_lunar_retroreflector"
    elif marker == $ALSEPMarker:
        discovery_id = "apollo_alsep"
    if discovery_id == "":
        return
    _open_discovery(discovery_id)

func _open_discovery(discovery_id: String) -> void:
    var item = _get_discovery_by_id(discovery_id)
    if item == null:
        return
    current_discovery_id = discovery_id
    discovery_panel.visible = true
    creation_buttons(item)
    discovery_title.text = item["name"]
    discovery_meta.text = "Mission: %s | Year: %s\nSource: %s" % [item["mission"], item["year"], item["source_url"]]
    discovery_description.text = item["historical_description"] + "\n\nPurpose: " + item["purpose"]
    challenge_label.text = item["educational_challenge"]
    _set_message("Mission Control: That object is real history. It still carries the shape of an earlier world.")

func _get_discovery_by_id(discovery_id: String):
    for item in discovery_data:
        if item.get("id") == discovery_id:
            return item
    return null

func creation_buttons(item: Dictionary) -> void:
    for button in current_answer_buttons:
        button.queue_free()
    current_answer_buttons.clear()

    var options = item.get("answers", [])
    for index in range(options.size()):
        var button = Button.new()
        button.text = options[index]
        button.custom_minimum_size = Vector2(660, 38)
        button.pressed.connect(func(): _handle_answer(index, item["correct_answer_index"]))
        answer_buttons_container.add_child(button)
        current_answer_buttons.append(button)

func _handle_answer(selected_index: int, correct_index: int) -> void:
    if selected_index == correct_index:
        if not discovered_ids.has(current_discovery_id):
            discovered_ids.append(current_discovery_id)
            _save_state()
        _mark_marker_complete(current_discovery_id)
        _update_hud()
        _set_message("Mission Control: The signal is coherent now. The archive is not random — it is memory. ")
        discovery_panel.visible = false
        if discovered_ids.size() >= 3:
            _launch_transition()
    else:
        _set_message("Mission Control: Not quite. Look again at how the machine was designed to work.")

func _mark_marker_complete(id: String) -> void:
    if id == "apollo_lunar_module":
        $LunarModuleMarker.visible = false
    elif id == "apollo_lunar_retroreflector":
        $RetroreflectorMarker.visible = false
    elif id == "apollo_alsep":
        $ALSEPMarker.visible = false

func _update_hud() -> void:
    discovery_counter.text = "Discoveries: %d/3" % discovered_ids.size()
    objective_label.text = "Objective: Recover the Moon chapter and decode the signal" if discovered_ids.size() < 3 else "Objective: The lunar archive is complete"
    signal_label.text = "Signal: %s" % (["weak", "stable", "clear"][min(discovered_ids.size(), 2)])

func _launch_transition() -> void:
    transition_panel.visible = true
    transition_text.text = "The repeating signal is no longer random. It is a chain of memory fragments from human exploration: lunar landings, laser echoes, and the long silence after the last missions. Somewhere beyond the Moon, the archive waits."
    $CanvasLayer/HUD/TransitionPanel/ContinueButton.pressed.connect(_return_to_menu, CONNECT_ONE_SHOT)

func _return_to_menu() -> void:
    get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _set_message(new_text: String) -> void:
    mission_control_box.text = new_text

func _exit_tree() -> void:
    _save_state()
