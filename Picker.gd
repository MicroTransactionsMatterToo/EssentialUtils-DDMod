## Copyright MBMM 2023

var script_class = "tool"

var picker_enabled : bool = false
var filterMenu
var filter : Dictionary = {
    "Walls": true,
    "Portals": true,
    "Objects": true,
    "Paths": true,
    "Lights": true,
    "Patterns": true,
    "Roofs": true
}

var config = {
    "align_config": {
        "highlight_first": true
    }
}


func ui() -> void:
    var tool_panel = Global.Editor.Toolset.CreateModTool(self, "Objects", "PickerTool", "Picker Tool", "res://ui/icons/buttons/color_wheel.png")

    var filterButton = MenuButton.new()
    filterButton.text = "Filter"
    filterButton.flat = false
    
    filterMenu = filterButton.get_popup()
    filterMenu.hide_on_checkable_item_selection = false
    filterMenu.add_check_item("All", -1, 0)
    var filter_options = ["Walls", "Portals", "Objects", "Paths", "Lights", "Patterns", "Roofs"]

    var idx = 1
    for option in filter_options:
        filterMenu.add_check_item(option, idx)
        filterMenu.set_item_checked(idx, true)
        idx += 1
    
    filterMenu.connect("id_pressed", self, "set_filter_state", null, 0)

    tool_panel.align.add_child(filterButton, false)

    tool_panel.UsesObjectLibrary = false


func start():
    self.ui()
    # _lib integration
    if Engine.has_signal("_lib_register_mod"):
        Engine.emit_signal("_lib_register_mod", self)

        var input_defs = {
            "Change to Picker": ["switch_to_picker", "P"]
        }

        Global.API.InputMapApi.define_actions("Picker", input_defs)


func update(delta):
    # Inefficient way to bind a global shortcut for picking, but it's the only way because _Input isn't recieved by Mod tools
    if Engine.has_signal("_lib_register_mod"):
        if Input.is_action_pressed("switch_to_picker") and not Global.Editor.SearchHasFocus:
            Global.Editor.Toolset.Quickswitch("PickerTool")
    else:
        if Input.is_key_pressed(KEY_P) and not Global.Editor.SearchHasFocus:
            Global.Editor.Toolset.Quickswitch("PickerTool")


func set_filter_state(index: int) -> void:
    if index == 0:
        var newState = !filterMenu.is_item_checked(0)
        for itemIndex in filterMenu.get_item_count():
            filterMenu.set_item_checked(itemIndex, newState)
            filter[filterMenu.get_item_text(itemIndex)] = newState
    else:
        var itemName = filterMenu.get_item_text(index)
        var newState = !filterMenu.is_item_checked(index)
        filter[itemName] = newState
        filterMenu.set_item_checked(index, newState)

        var allChecked = true
        for val in filter.values():
            if allChecked and not val:
                allChecked = false
        filterMenu.set_item_checked(0, allChecked)


func on_tool_enable(tool_id) -> void:
    picker_enabled = true
    Global.World.Level.Lights.EnableWidgets(true, false)


func on_tool_disable(tool_id) -> void:
    picker_enabled = false
    Global.World.Level.Lights.EnableWidgets(false, false)


func on_content_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT and event.pressed:
            var object_picked = false
            if filter["Portals"] and not object_picked:
                object_picked = pick_portal()
            if filter["Objects"] and not object_picked:
                object_picked = pick_object()
            if filter["Walls"] and not object_picked:
                object_picked = pick_wall()
            if filter["Lights"] and not object_picked:
                object_picked = pick_light()
            if filter["Paths"] and not object_picked:
                object_picked = pick_path()
            if filter["Patterns"] and not object_picked:
                object_picked = pick_patternshape()
            if filter["Roofs"] and not object_picked:
                object_picked = pick_roof()


func pick_portal() -> void:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]

    for portal in currentLevel.Portals.get_children():
        if portal.IsMouseWithin():
            # Long winded, because if you try to cache the tool locally it breaks things
            Global.Editor.Tools["PortalTool"].textureMenu.SelectTexture(portal.Texture)
            Global.Editor.Tools["PortalTool"].Texture = portal.Texture
            Global.Editor.Tools["PortalTool"].Flip = portal.Flip
            Global.Editor.Tools["PortalTool"].Closed = portal.Closed
            Global.Editor.Tools["PortalTool"].Freestanding = portal.IsFreestanding
            if portal.IsFreestanding:
                Global.Editor.Tools["PortalTool"].Rotation.set_value(rad2deg(portal.Direction.angle()))
            
            Global.Editor.Toolset.Quickswitch("PortalTool")
            return

    for wall in currentLevel.Walls.get_children():
        for portal in wall.get_children():
            if portal.Closed != null and portal.IsFreestanding != null:
                if portal.IsMouseWithin():
                    # Long winded, because if you try to cache the tool locally it breaks things
                    Global.Editor.Tools["PortalTool"].textureMenu.SelectTexture(portal.Texture)
                    Global.Editor.Tools["PortalTool"].Texture = portal.Texture
                    Global.Editor.Tools["PortalTool"].Flip = portal.Flip
                    Global.Editor.Tools["PortalTool"].Closed = portal.Closed
                    Global.Editor.Tools["PortalTool"].Freestanding = portal.IsFreestanding
                    if portal.IsFreestanding:
                        Global.Editor.Tools["PortalTool"].Rotation.set_value(rad2deg(portal.Direction.angle()))
                    
                    Global.Editor.Toolset.Quickswitch("PortalTool")
                    return


func pick_object() -> bool:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]

    var object_list = currentLevel.Objects.get_children()
    # Reverse the object list, as it's ordered from backmost to foremost
    object_list.invert()

    var packsUsed = []

    for obj in object_list:
        # Method to check if mouse is over a non-transparent pixel of the sprite attached to an object
        if obj.Sprite.is_pixel_opaque(obj.Sprite.to_local(mousePos)):
            # Setting the current selected object in the ObejctLibrary UI
            Global.Editor.Tools["ObjectTool"].LibraryMemory["selected"] = [obj.Texture.resource_path]

            # Setting the actual texture used for preview and creating objects
            Global.Editor.Tools["ObjectTool"].Texture = obj.Texture
            Global.Editor.Tools["ObjectTool"].Rotation.set_value(rad2deg(obj.GlobalRotation))

            Global.Editor.Tools["ObjectTool"].Scale.set_value(obj.GlobalScale.x)

            Global.Editor.Tools["ObjectTool"].Shadow = obj.HasShadow
            Global.Editor.Tools["ObjectTool"].Controls["Shadow"].pressed = obj.HasShadow
            Global.Editor.Tools["ObjectTool"].Preview.HasShadow = obj.HasShadow
        
            Global.Editor.Tools["ObjectTool"].BlockLight = obj.BlockLight
            Global.Editor.Tools["ObjectTool"].Controls["BlockLight"].set_pressed_no_signal(obj.BlockLight)

            if obj.hasCustomColor:
                Global.Editor.Tools["ObjectTool"].customColor = obj.customColor
                Global.Editor.Tools["ObjectTool"].PromoteCustomColor()

            # Switch tools
            Global.Editor.Toolset.Quickswitch("ObjectTool")
            Global.Editor.Tools["ObjectTool"].Preview.BlockLight = obj.BlockLight

            return true
    return false


func pick_path() -> bool:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]

    for path in currentLevel.Pathways.get_children():
        # For some reason, this IsMouseWithin takes a mouse position.
        if path.IsMouseWithin(mousePos):
            Global.Editor.Tools["PathTool"].LibraryMemory["selected"] = [path.get_texture().resource_path]
            Global.Editor.Tools["PathTool"].Texture = path.get_texture()
            
            Global.Editor.Toolset.Quickswitch("PathTool")
            return true
    return false


func pick_wall() -> bool:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]

    for wall in currentLevel.Walls.get_children():
        # For some reason, this IsMouseWithin takes a mouse position.
        if wall.IsMouseWithin(mousePos):
            # WallTool has it's GridMenu stored under Controls
            Global.Editor.Tools["WallTool"].Controls["Texture"].SelectTexture(wall.Texture)
            Global.Editor.Tools["WallTool"].Texture = wall.Texture
            Global.Editor.Tools["WallTool"].SetWallColor(wall.Color)
            Global.Editor.Tools["WallTool"].Controls["Bevel"].pressed = true if wall.Joint == 1 else false
            Global.Editor.Tools["WallTool"].Controls["Shadow"].pressed = wall.HasShadow

            
            Global.Editor.Toolset.Quickswitch("WallTool")
            return true
    return false


func pick_patternshape() -> bool:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]
    
    # Have to use GetShapes, because PatternShapes.Layers is a SortedDict, which breaks GDScript
    for shape in currentLevel.PatternShapes.GetShapes():
        # Using is_point_inside instead of IsMouseWithin because otherwise it crashes
        if shape.is_point_inside(mousePos):
            # textureMenu is of type GridMenu, and allows you to set the selected option using SelectTexture
            Global.Editor.Tools["PatternShapeTool"].textureMenu.SelectTexture(shape._Texture)
            # Just setting the menu isn't enough, to actually set what texture is used in new patternshapes, you need to set _Texture
            Global.Editor.Tools["PatternShapeTool"].Texture = shape._Texture
            # Ensuring that we don't accidentally draw a shape on switching tools
            Global.Editor.Tools["PatternShapeTool"].boxBegin = Global.World.get_global_mouse_position()
            Global.Editor.Tools["PatternShapeTool"].boxEnd = Global.World.get_global_mouse_position()

            Global.Editor.Tools["PatternShapeTool"].ChangeColor(shape.Color, "")
            Global.Editor.Tools["PatternShapeTool"].Rotation.set_value(rad2deg(shape._Rotation))
            Global.Editor.Tools["PatternShapeTool"].Controls["Outline"].pressed = shape.HasOutline

            yield(shape.get_tree().create_timer(0.1), "timeout")

            # Switch tools
            Global.Editor.Toolset.Quickswitch("PatternShapeTool")
            return true
    return false


func pick_light() -> bool:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]

    # Fetch lights
    var light_array = currentLevel.Lights.get_children()
    light_array.invert()

    for light in light_array:
        # Have to do it like this, using light.GetWidget causes crashes
        var lightWidget = light.get_child(0)
        if lightWidget.IsMouseWithin():
            Global.Editor.Tools["LightTool"].texture = light.get_texture()
            Global.Editor.Tools["LightTool"].Intensity = light.energy
            Global.Editor.Tools["LightTool"].Range.set_value(((light.get_texture_scale() * light.get_texture().get_width()) / 512.0))
            Global.Editor.Toolset.Quickswitch("LightTool")
            Global.Editor.Tools["LightTool"].Controls["Texture"].SelectTexture(light.get_texture())
            return true
    return false


func pick_roof() -> bool:
    var mousePos = Global.World.get_global_mouse_position()
    var currentLevel = Global.World.levels[Global.World.CurrentLevelId]

    for roof in currentLevel.Roofs.get_children():
        if roof.IsMouseWithin():
            Global.Editor.Tools["RoofTool"].Texture = roof.TilesTexture
            Global.Editor.Tools["RoofTool"].Controls["Texture"].SelectTexture(roof.TilesTexture)

            Global.Editor.Tools["RoofTool"].boxBegin = Global.World.UI.SnappedPosition
            Global.Editor.Tools["RoofTool"].boxEnd = Global.World.UI.SnappedPosition

            Global.Editor.Tools["RoofTool"].SetShade(roof.shade)
            Global.Editor.Tools["RoofTool"].ShadeContrast.set_value(roof.shadeContrast)
            Global.Editor.Tools["RoofTool"].Type = roof.type
            Global.Editor.Tools["RoofTool"].Width.set_value(roof.width / Global.World.Instance.TileSize)


            # Have to delay switching tools, because the RoofTool otherwise has a tendency to create roofs on switch
            yield(roof.get_tree().create_timer(0.1), "timeout")

                
            Global.Editor.Toolset.Quickswitch("RoofTool")
            return true
    return false