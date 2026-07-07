extends PanelContainer

const OPEN_HEIGHT := 300.0
const CLOSED_HEIGHT := 36.0
const MENU_WIDTH := 520.0

var active_page: Control = null

@onready var content_panel: Control = $MenuLayout/ContentPanel
@onready var character_page: Control = $MenuLayout/ContentPanel/Content/CharacterPage
@onready var skills_page: Control = $MenuLayout/ContentPanel/Content/SkillsPage
@onready var inventory_page: Control = $MenuLayout/ContentPanel/Content/InventoryPage
@onready var settings_page: Control = $MenuLayout/ContentPanel/Content/SettingsPage
@onready var equipment_panel: Control = $MenuLayout/ContentPanel/Content/EquipmentPanel

@onready var character_button: Button = $MenuLayout/MenuButtons/Character
@onready var skills_button: Button = $MenuLayout/MenuButtons/Skills
@onready var inventory_button: Button = $MenuLayout/MenuButtons/Inventory
@onready var equipment_button: Button = $MenuLayout/MenuButtons/Equipment
@onready var settings_button: Button = $MenuLayout/MenuButtons/Settings
@onready var reload_button: Button = $MenuLayout/ContentPanel/Content/SettingsPage/Reload

func _ready():
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -MENU_WIDTH
	offset_right = 0.0
	offset_bottom = 0.0
	custom_minimum_size = Vector2(MENU_WIDTH, OPEN_HEIGHT)

	disable_button_focus()

	character_button.pressed.connect(toggle_character_page)
	skills_button.pressed.connect(toggle_skills_page)
	inventory_button.pressed.connect(toggle_inventory_page)
	equipment_button.pressed.connect(toggle_equipment_panel)
	settings_button.pressed.connect(toggle_settings_page)
	reload_button.pressed.connect(reload_game)

	hide_all_pages()

func toggle_character_page():
	toggle_page(character_page)

func toggle_skills_page():
	toggle_page(skills_page)

func toggle_inventory_page():
	toggle_page(inventory_page)

func toggle_settings_page():
	toggle_page(settings_page)

func toggle_page(page: Control):
	if active_page == page:
		page.visible = false
		active_page = null

		if not equipment_panel.visible:
			hide_all_pages()

		return

	hide_content_pages()
	content_panel.visible = true
	page.visible = true
	active_page = page
	set_menu_height(OPEN_HEIGHT)

func toggle_equipment_panel():
	equipment_panel.visible = not equipment_panel.visible

	if equipment_panel.visible:
		content_panel.visible = true
		set_menu_height(OPEN_HEIGHT)
	elif active_page == null:
		hide_all_pages()

func hide_content_pages():
	character_page.visible = false
	skills_page.visible = false
	inventory_page.visible = false
	settings_page.visible = false
	active_page = null

func hide_all_pages():
	hide_content_pages()
	equipment_panel.visible = false
	content_panel.visible = false
	set_menu_height(CLOSED_HEIGHT)

func set_menu_height(height: float):
	offset_top = -height
	custom_minimum_size = Vector2(MENU_WIDTH, height)

func disable_button_focus():
	character_button.focus_mode = Control.FOCUS_NONE
	skills_button.focus_mode = Control.FOCUS_NONE
	inventory_button.focus_mode = Control.FOCUS_NONE
	equipment_button.focus_mode = Control.FOCUS_NONE
	settings_button.focus_mode = Control.FOCUS_NONE
	reload_button.focus_mode = Control.FOCUS_NONE

func reload_game():
	get_tree().reload_current_scene()
