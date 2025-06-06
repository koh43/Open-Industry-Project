@tool
class_name Shelf
extends ResizableNode3D

signal size_changed

const DEFAULT_LENGTH: float = 2.0
const DEFAULT_HEIGHT: float = 2.0
const DEFAULT_DEPTH: float = 0.5
const DEFAULT_SHELF_COUNT: int = 3

@export_custom(PROPERTY_HINT_NONE, "suffix:m") 
var length: float:
    set(value):
        size.x = value
    get:
        return size.x

@export_custom(PROPERTY_HINT_NONE, "suffix:m") 
var height: float:
    set(value):
        size.y = value
    get:
        return size.y

@export_custom(PROPERTY_HINT_NONE, "suffix:m") 
var depth: float:
    set(value):
        size.z = value
    get:
        return size.z

@export_range(1, 10, 1)
var shelf_count: int = DEFAULT_SHELF_COUNT:
    set(value):
        if shelf_count != value:
            shelf_count = value
            _update_shelves()

@export
var shelf_thickness: float = 0.05:
    set(value):
        if shelf_thickness != value:
            shelf_thickness = value
            _update_shelves()

# Internal nodes
@onready var _frame: Node3D = $Frame
@onready var _shelves: Node3D = $Shelves
@onready var _static_body: StaticBody3D = $StaticBody3D

var _last_size: Vector3
var _shelf_scenes: Array[Node3D] = []

func _init() -> void:
    super._init()
    size_default = Vector3(DEFAULT_LENGTH, DEFAULT_HEIGHT, DEFAULT_DEPTH)

func _ready() -> void:
    if not _frame:
        _setup_nodes()
    _update_shelf_structure()

func _setup_nodes() -> void:
    # Create frame node for the shelf structure
    _frame = Node3D.new()
    _frame.name = "Frame"
    add_child(_frame)
    
    # Create shelves container
    _shelves = Node3D.new()
    _shelves.name = "Shelves"
    add_child(_shelves)
    
    # Create static body for physics
    _static_body = StaticBody3D.new()
    _static_body.name = "StaticBody3D"
    add_child(_static_body)

func _process(_delta: float) -> void:
    if _last_size != size:
        _update_shelf_structure()
        _last_size = size
        size_changed.emit()

func _update_shelf_structure() -> void:
    _update_frame()
    _update_shelves()
    _update_collision()

func _update_frame() -> void:
    if not _frame:
        return
    
    # Clear existing frame elements
    for child in _frame.get_children():
        child.queue_free()
    
    # Create vertical supports
    _create_vertical_support(Vector3(-length/2, 0, -depth/2))
    _create_vertical_support(Vector3(length/2, 0, -depth/2))
    _create_vertical_support(Vector3(-length/2, 0, depth/2))
    _create_vertical_support(Vector3(length/2, 0, depth/2))

func _create_vertical_support(pos: Vector3) -> void:
    var support = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(0.05, height, 0.05)
    support.mesh = box_mesh
    support.position = pos + Vector3(0, height/2, 0)
    
    # Add material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.3, 0.3)
    support.material_override = material
    
    _frame.add_child(support)

func _update_shelves() -> void:
    if not _shelves:
        return
    
    # Clear existing shelves
    for child in _shelves.get_children():
        child.queue_free()
    
    # Create shelves
    for i in range(shelf_count):
        var shelf_y = (i + 1) * (height / (shelf_count + 1))
        _create_shelf(Vector3(0, shelf_y, 0))

func _create_shelf(pos: Vector3) -> void:
    var shelf = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(length, shelf_thickness, depth)
    shelf.mesh = box_mesh
    shelf.position = pos
    
    # Add material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.8, 0.6, 0.4)  # Wood color
    shelf.material_override = material
    
    _shelves.add_child(shelf)

func _update_collision() -> void:
    if not _static_body:
        return
    
    # Clear existing collision shapes
    for child in _static_body.get_children():
        child.queue_free()
    
    # Add collision for frame
    for support_pos in [
        Vector3(-length/2, height/2, -depth/2),
        Vector3(length/2, height/2, -depth/2),
        Vector3(-length/2, height/2, depth/2),
        Vector3(length/2, height/2, depth/2)
    ]:
        var collision_shape = CollisionShape3D.new()
        var box_shape = BoxShape3D.new()
        box_shape.size = Vector3(0.05, height, 0.05)
        collision_shape.shape = box_shape
        collision_shape.position = support_pos
        _static_body.add_child(collision_shape)
    
    # Add collision for shelves
    for i in range(shelf_count):
        var shelf_y = (i + 1) * (height / (shelf_count + 1))
        var collision_shape = CollisionShape3D.new()
        var box_shape = BoxShape3D.new()
        box_shape.size = Vector3(length, shelf_thickness, depth)
        collision_shape.shape = box_shape
        collision_shape.position = Vector3(0, shelf_y, 0)
        _static_body.add_child(collision_shape)

func _validate_property(property: Dictionary) -> void:
    var property_name = property["name"]
    if property_name in ["length", "height", "depth"]:
        property["usage"] = PROPERTY_USAGE_EDITOR
    if property_name == "size":
        property["usage"] = PROPERTY_USAGE_STORAGE

func _property_can_revert(property: StringName) -> bool:
    match property:
        &"length":
            return true
        &"height":
            return true
        &"depth":
            return true
        &"shelf_count":
            return true
        _:
            return false

func _property_get_revert(property: StringName) -> Variant:
    match property:
        &"length":
            return DEFAULT_LENGTH
        &"height":
            return DEFAULT_HEIGHT
        &"depth":
            return DEFAULT_DEPTH
        &"shelf_count":
            return DEFAULT_SHELF_COUNT
        _:
            return null