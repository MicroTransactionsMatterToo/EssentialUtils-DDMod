## Copyright MBMM 2023

var script_class = "tool"
var align_button_group: ButtonGroup

var align_container: HBoxContainer
var is_alignable_selection = true




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

func load_button_icon(path: String) -> ImageTexture:
    var image = Image.new()
    image.load(path)
    var tx = ImageTexture.new()
    tx.create_from_image(image)

    return tx


func start():
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
            align_container.add_spacer()
        if i == 6:
            align_container.add_spacer()
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


func update(delta: float):
    # We don't need to check on every single frame
    if not (fmod(delta, 10)): return
    # else:
    #     print(Master.IsLoadingMap)
    #     print(Master.IsEditing)
    if Global.Editor.Toolset.ToolPanels["SelectTool"].visible:
        var stool = Global.Editor.Tools["SelectTool"]
        var selected = stool.Selected
        # We can only align Portals (unanchored), Objects and Lights
        is_alignable_selection = false
        if selected.size() != 0:
            is_alignable_selection = true
            for selected_object in selected:
                if stool.Selectables[selected_object] in [0, 1, 3, 5, 7, 8]:
                    is_alignable_selection = false

        for button in align_container.get_children():
            button.disabled = !is_alignable_selection



func on_align_pressed(align_index: int):
    ## TODO: Implement undo and redo once the MoveRecord and MultiRecord objects are accessible from GDScript
    # # Store position of current selections before any changes are made
    # # This is for handling the undo and redo stuff later
    # var pre_align_positions = {}
    # for prop in Global.Editor.Tools["SelectTool"].Selected:
    #     pre_align_positions[prop] = prop.position

    # Dispatch to appropriate handler
    match align_index:
        ALIGN_TYPE.Start:
            print("Align start")
            align_left()
        ALIGN_TYPE.Center:
            print("Align center")
            align_center()
        ALIGN_TYPE.End:
            print("Align end")
            align_right()
        ALIGN_TYPE.Top:
            print("Align top")
            align_top()
        ALIGN_TYPE.Middle:
            print("Align middle")
            align_middle()
        ALIGN_TYPE.Bottom:
            print("Align bottom")
            align_bottom()
        ALIGN_TYPE.DistributeHoriz:
            print("Dist Horiz")
            distribute_horizontally()
        ALIGN_TYPE.DistributeVert:
            print("Dist vert")
            distribute_vertically()
        _:
            print("Unknown align index")
    Global.Editor.Tools["SelectTool"].EnableTransformBox(true)
    

func align_center():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    # We'll align to the first object in the array for now
    var root_object: Node2D = selected[0]
    var root_x = root_object.position.x

    for i in range(1, selected.size()):
        selected[i].position.x = root_x

func align_middle():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    # We'll align to the first object in the array for now
    var root_object: Node2D = selected[0]
    var root_y = root_object.position.y

    for i in range(1, selected.size()):
        selected[i].position.y = root_y

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

func distribute_horizontally():
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

func distribute_vertically():
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


## Function to return bounds of a given prop
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

# func get_side_offsets(prop: Node2D):
#     var stool = Global.Editor.Tools["SelectTool"]

#     match stool.Selectables[prop]:
#         2, 4:
#             var sides = get_sides(prop)
#             var side_offsets = {

#             }

func align_left():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    print("Get Sides for Root: " + str(root))
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            print("Object " + str(i) + " position = " + str(selected[i].position))
            selected[i].position.x = root["west"] + prop_sides["x_offset"]


func align_right():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    print("Get Sides for Root: " + str(root))
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            print("Object " + str(i) + " position = " + str(selected[i].position))
            selected[i].position.x = root["east"] - prop_sides["x_offset"]

func align_bottom():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    print("Get Sides for Root: " + str(root))
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            print("Object " + str(i) + " position = " + str(selected[i].position))
            selected[i].position.y = root["north"] - prop_sides["y_offset"]

func align_top():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    var root = get_sides(selected[0])
    print("Get Sides for Root: " + str(root))
    if root != null:
        for i in range(1, selected.size()):
            var prop_sides = get_sides(selected[i])
            print("Object " + str(i) + " position = " + str(selected[i].position))
            selected[i].position.y = root["south"] + prop_sides["y_offset"]