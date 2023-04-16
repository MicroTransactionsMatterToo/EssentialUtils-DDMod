## Copyright MBMM 2023

var script_class = "tool"
var filter_button: BaseButton

var filter_button_enabled = false

func start():
    var tool_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")

    filter_button = tool_panel.CreateButton("Select Similar", "res://ui/icons/misc/box.png")
    filter_button.connect("pressed", self, "select_alike")

func update(delta: float):
    if not (fmod(delta, 10.0)): return
    if Global.Editor.Toolset.ToolPanels["SelectTool"].visible:
        var stool = Global.Editor.Tools["SelectTool"]
        var selected = stool.Selected

        if selected.size() == 1:
            filter_button.visible = true
            return
    filter_button.visible = false

func select_alike():
    var stool = Global.Editor.Tools["SelectTool"]
    match stool.Selectables[stool.Selected[0]]:
        1:
            select_walls()
        2,3:
            select_portals()
        4:
            select_objects()
        5:
            select_paths()
        7:
            select_patternshapes()
        8:
            select_roofs()
        _:
            return



func select_portals():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for portal in currentLevel.Portals.get_children():
        if portal.Texture == match_object.Texture:
            matching_objects.push_back(portal)
    
    for wall in currentLevel.Walls.get_children():
        for portal in wall.get_children():
            if portal.Texture == match_object.Texture:
                matching_objects.push_back(portal)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)

func select_objects():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for obj in currentLevel.Objects.get_children():
        if obj.Texture == match_object.Texture and obj.customColor == match_object.customColor:
            matching_objects.push_back(obj)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)

func select_paths():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for path in currentLevel.Pathways.get_children():
        if path.get_texture() == match_object.get_texture():
            matching_objects.push_back(path)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)

func select_walls():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for wall in currentLevel.Walls.get_children():
        if wall.Color == match_object.Color and wall.Texture == match_object.Texture:
            matching_objects.push_back(wall)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)

func select_patternshapes():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for shape in currentLevel.PatternShapes.GetShapes():
        if shape._Texture == match_object._Texture and \
            shape._Rotation == match_object._Rotation and\
            shape.Color == match_object.Color:
            matching_objects.push_back(shape)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)
        
func select_lights():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for light in currentLevel.Lights.get_children():
        if light.get_texture() == match_object.get_texture():
            matching_objects.push_back(light)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)

func select_roofs():
    var stool = Global.Editor.Tools["SelectTool"]
    var currentLevel = Global.World.GetLevelByID(Global.World.CurrentLevelId)
    var match_object = stool.Selected[0]

    var matching_objects = []

    for roof in currentLevel.Roofs.get_children():
        if roof.TilesTexture == match_object.TilesTexture and\
            roof.type == match_object.type:
            matching_objects.push_back(roof)
    
    for item in matching_objects:
        if item != match_object:
            stool.SelectThing(item, true)