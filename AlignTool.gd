## Copyright MBMM 2023
class_name AlignTool

var script_class = "tool"
var align_button_group: ButtonGroup

var align_container: HBoxContainer
var is_alignable_selection = true

var old_root_node = null


enum ALIGN_TYPE {
    Start,
    Center,
    End,
    Top,
    Middle,
    Bottom,
    DistributeHoriz,
    DistributeVert
}

var config = {
    "align_config": {
        "highlight_first": true
    }
}


func load_button_icon(path: String) -> ImageTexture:
    var image = Image.new()
    image.load(path)
    var tx = ImageTexture.new()
    tx.create_from_image(image)

    return tx

func ui() -> void:
    var tool_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")

    var align_button_icons = [
        Global.Root + "icons/align-start.png",
        Global.Root + "icons/align-center.png",
        Global.Root + "icons/align-end.png",
        Global.Root + "icons/align-top.png",
        Global.Root + "icons/align-middle.png",
        Global.Root + "icons/align-bottom.png",
        Global.Root + "icons/distribute-horizontal.png",
        Global.Root + "icons/distribute-vertical.png"
    ]

    var align_button_hints = [
        "Align at left",
        "Align at center",
        "Align at right",
        "Align at top",
        "Align at middle",
        "Align at bottom",
        "Distribute horizontally",
        "Distribute vertically"
    ]

    align_container = HBoxContainer.new()
    align_container.size_flags_horizontal = 3
    
    var buttons = []

    for i in align_button_icons.size():
        if i == 3:
            align_container.add_spacer(false)
        if i == 6:
            align_container.add_spacer(false)
        var button = Button.new()
        button.icon = load_button_icon(align_button_icons[i])
        button.toggle_mode = false
        button.group = align_button_group
        button.hint_tooltip = align_button_hints[i]
        button.size_flags_horizontal = 2
        button.connect("pressed", self, "on_align_pressed", [i])
        align_container.add_child(button)
        buttons.push_back(button)

    var align_label = Label.new()
    align_label.text = "Alignment Tools"
    
    var align_separator = HSeparator.new()

    tool_panel.Align.add_child(align_label)
    tool_panel.Align.move_child(align_label, 12)
    tool_panel.Align.add_child(align_container, false)
    tool_panel.Align.move_child(align_container, 13)
    tool_panel.Align.add_child(align_separator)
    tool_panel.Align.move_child(align_separator, 14)

## Uses the _Lib mod to create a preferences UI
func config_ui() -> void:
    if Engine.has_signal("_lib_register_mod"):
        Engine.emit_signal("_lib_register_mod", self)
        var config_builder = self.Global.API.ModConfigApi.create_config(
            "MBMM.ess_utils", 
            "EssentialUtils", 
            "user://ess_utils_config.json"
        )
        var margin = 20
        var bold_text_node = RichTextLabel.new()
        bold_text_node.bbcode_enabled = true
        bold_text_node.visible = true
        # bold_text_node.size_flags_horizontal = 2
        bold_text_node.fit_content_height = true
        bold_text_node.parse_bbcode("[b]AlignTool Settings[/b]")
        config = config_builder\
            .margin_container()\
                .with("margin_left", margin)\
                .with("margin_right", margin)\
                .with("margin_top", margin)\
                .with("margin_bottom", margin)\
            .enter()\
                .v_box_container("align_config").enter()\
                    .add_node(bold_text_node)\
                    .h_separator()\
                    .check_button("highlight_first", true, "Highlight object used for alignment")\
                .exit()\
            .exit()\
            .build()

func start():
    var tool_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")
    self.ui()
    # _lib integration
    self.config_ui()

    


func update(delta: float):
    # We don't need to check on every single frame
    if not (fmod(delta, 10)): return

    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    # Handle toggle for item highlighting
    var highlight_first = true
    if Engine.has_signal("_lib_register_mod"):
        highlight_first = config.align_config.highlight_first
    else:
        highlight_first = config["align_config"]["highlight_first"]

    # If the old first object is not the same as the current one, hide the widget
    if old_root_node != selected[0]:
        if old_root_node != null and old_root_node.has_node("AlignFirstItemWidget"):
            old_root_node.get_node("AlignFirstItemWidget").visible = false
    
    # Stuff we only do if the SelectTool is active
    if Global.Editor.Toolset.ToolPanels["SelectTool"].visible:
        # We can only align Portals (unanchored), Objects and Lights
        is_alignable_selection = false
        if selected.size() != 0:
            is_alignable_selection = true
            for selected_object in selected:
                if stool.Selectables[selected_object] in [0, 1, 3, 5, 7, 8]:
                    is_alignable_selection = false

        for button in align_container.get_children():
            button.disabled = !is_alignable_selection
        
        if is_alignable_selection:
            if highlight_first:
                if not selected[0].has_node("AlignFirstItemWidget"):
                    # Create and add a widget that shows a green box on object everything else will align to
                    var align_widget = AlignFirstItemWidget.new()
                    align_widget.name = "AlignFirstItemWidget"
                    selected[0].add_child(align_widget, false)
                else:
                    selected[0].get_node("AlignFirstItemWidget").visible = true
            old_root_node = selected[0]


func on_align_pressed(align_index: int) -> void:
    # Record pre-align transforms
    Global.Editor.Tools["SelectTool"].SavePreTransforms()

    # Dispatch to appropriate handler
    match align_index:
        ALIGN_TYPE.Start:
            align_left()
        ALIGN_TYPE.Center:
            align_center()
        ALIGN_TYPE.End:
            align_right()
        ALIGN_TYPE.Top:
            align_top()
        ALIGN_TYPE.Middle:
            align_middle()
        ALIGN_TYPE.Bottom:
            align_bottom()
        ALIGN_TYPE.DistributeHoriz:
            distribute_horizontally()
        ALIGN_TYPE.DistributeVert:
            distribute_vertically()
        _:
            return

    # Save transforms for undo
    Global.Editor.Tools["SelectTool"].RecordTransforms()
    Global.Editor.Tools["SelectTool"].EnableTransformBox(true)
    

func align_center() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    # We'll align to the first object in the array for now
    var root_object: Node2D = selected[0]
    var root_x = root_object.position.x

    for i in range(1, selected.size()):
        selected[i].position.x = root_x

func align_middle() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    # We'll align to the first object in the array for now
    var root_object: Node2D = selected[0]
    var root_y = root_object.position.y

    for i in range(1, selected.size()):
        selected[i].position.y = root_y



func distribute_horizontally() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    # Copy Selected array so we can sort it
    var selected = stool.Selected.duplicate()
    # Sort from left to right
    selected.sort_custom(NodeSorter, "node_sort_hor")
    var start_position = selected[0].position
    var selection_span = selected[-1].position.x - selected[0].position.x
    var step = selection_span / (selected.size()  -1)

    for i in range(stool.Selected.size()):
        selected[i].position.x = (start_position.x + (step * i))

func distribute_vertically() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    # Copy Selected array so we can sort it
    var selected = stool.Selected.duplicate()
    # Sort from left to right
    selected.sort_custom(NodeSorter, "node_sort_vert")
    var start_position = selected[0].position
    var selection_span = selected[-1].position.y - selected[0].position.y
    var step = selection_span / (selected.size()  -1)

    for i in range(stool.Selected.size()):
        selected[i].position.y = (start_position.y + (step * i))

# Function to return bounds of a given prop
func get_sides(prop: Node2D):
    var stool = Global.Editor.Tools["SelectTool"]

    match stool.Selectables[prop]:
        2, 4:
            var sprite = prop.Sprite
            var sprite_bounds = sprite.get_rect()
            var bound_start = sprite.to_global(sprite_bounds.position)
            var bound_end = sprite.to_global(sprite_bounds.end)
            var x_values = [bound_start.x, bound_end.x]
            var y_values = [bound_start.y, bound_end.y]
            x_values.sort()
            y_values.sort()
            return {
                "north": y_values[-1],
                "south": y_values[0],
                "east": x_values[-1],
                "west": x_values[0],
                "x_offset": x_values[-1] - prop.position.x,
                "y_offset": y_values[-1] - prop.position.y
            }
        6:
            var light_widget = prop.get_child(0)
            var range_line = light_widget.edge.get_points()
            var x_values = []
            var y_values = []
            for point in range_line:
                var glob_point = light_widget.edge.to_global(point)
                x_values.append(glob_point.x)
                y_values.append(glob_point.y)
            
            x_values.sort()
            y_values.sort()

            return {
                "north": y_values[-1],
                "south": y_values[0],
                "east": x_values[-1],
                "west": x_values[0],
                "x_offset": x_values[-1] - prop.position.x,
                "y_offset": y_values[-1] - prop.position.y
            }
        _:
            return null

func align_left() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            selected[i].position.x = root["west"] + prop_sides["x_offset"]


func align_right() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            selected[i].position.x = root["east"] - prop_sides["x_offset"]

func align_bottom() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            selected[i].position.y = root["north"] - prop_sides["y_offset"]

func align_top() -> void:
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            selected[i].position.y = root["south"] + prop_sides["y_offset"]

class NodeSorter:
    # L to R sort of Node2D
    static func node_sort_hor(a, b):
        if a.position.x < b.position.x:
            return true
        else:
            return false
    
    # Top to Bottom sort of Node2D
    static func node_sort_vert(a, b):
        if a.position.y > b.position.y:
            return true
        else:
            return false

# Widget for displaying which item is being align to
class AlignFirstItemWidget extends Node2D:
    func _draw() -> void:
        if self.get_parent().SelectRect != null:
            var color = Color.green
            color.a = 0.3
            self.draw_rect(self.get_parent().SelectRect, color, true, 1.0, false)
