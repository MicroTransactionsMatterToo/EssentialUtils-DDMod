## Copyright MBMM 2023

var script_class = "tool"
var enable_button: BaseButton

var infobox: PackedScene
var infobox_instance

var dw: PackedScene
var dw_instance: WindowDialog

var infobox_visible: bool
var pack_audit
var DEBUG = false

func start():
    var tool_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")

    enable_button = tool_panel.CreateButton("Show object info", "res://ui/icons/buttons/guide.png")
    enable_button.toggle_mode = true
    enable_button.connect("toggled", self, "toggle_asset_info")

    load_infobox()
    load_detailwindow()

func debugp(msg):
    if DEBUG:
        print(msg)
    else:
        pass

func update(delta: float):
    if not (fmod(delta, 10.0)): return
    else:
        var curr_prop = fetch_prop_info()
        if (curr_prop != null):
            var vbox = infobox_instance.get_node("VBoxContainer")
            var Xlbl = vbox.get_node("X/val")
            var Ylbl = vbox.get_node("Y/val")
            var assetName = vbox.get_node("AssetName/val")
            var assetPack = vbox.get_node("AssetPack/val")
            var prop_info = get_prop_pack(curr_prop)

            if (prop_info["packInfo"].Name == null and prop_info.objectName != null):
                assetPack.text = "DungeonDraft Built-in"
            else:
                assetPack.text = prop_info["packInfo"].Name

            assetName.text = prop_info.objectName
            Xlbl.text = curr_prop.position.x
            Ylbl.text = curr_prop.position.y

    if Global.Editor.Toolset.ToolPanels["SelectTool"].visible:
        infobox_instance.visible = infobox_visible
    else:
        infobox_instance.visible = false




func fetch_prop_info():
    var stool = Global.Editor.Tools["SelectTool"]
    var selected = stool.Selected

    if selected.size() >= 1:
        return selected[0]

func get_prop_pack(prop: Node2D) -> Dictionary:
    var stool = Global.Editor.Tools["SelectTool"]
    var objTexture = get_texture(prop)
    objTexture = objTexture.resource_path
    var packID = objTexture.right(12).split("/")[0]
    var objectPackName = objTexture.right(12).split("/")[-1]
    var pack = Global.Editor.owner.AssetPacks.get(packID)
    
    return {"packInfo": pack, "packID": packID, "objectName": objectPackName}

func identify_pack(texture: Texture) -> Dictionary:
    if (texture.resource_path.left(12) == "res://packs/"):
        var texture_path = texture.resource_path.right(12).split("/")
        var pack = Global.Editor.owner.AssetPacks.get(texture_path[0])
        return {
            "pack": pack,
            "packID": texture_path[0],
            "texture": texture_path[-1],
            "packName": pack.Name
        }
    else:
        return {
            "pack": null,
            "packID": null,
            "texture": texture.resource_path.right(6).split("/")[-1],
            "packName": "default"
        }
    

func get_used_tile_textures(level):
    var textures = {}
    for id in level.TileMap.tile_set.get_tiles_ids():
        textures[id] = level.TileMap.tile_set.tile_get_texture(id)
        debugp(textures[id].resource_path)
    return textures

# Appends identified assets from a pack to the overall list
func append_pack_items(pack_info: Dictionary, obj_type: String, pack_list: Array) -> void:
    pack_info["objType"] = obj_type
    if (not pack_list.has(pack_info["packID"])):
        pack_list[pack_info["packID"]] = []
    pack_list[pack_info["packID"]].append(pack_info)

# Determines which packs are used, and what assets from those packs are used
#
# Audit output is similar to the following
# ```
# var example = {
# 	"packID": [
#       {
#           "pack": <Pack Object>,
#           "packID": "packID",
#           "texture": "texturePath",
#           "packName": "Example Pack"
#       } 
#   ]
# }
# ```
func audit_asset_packs() -> Dictionary:
    debugp("Audit called")
    var pack_list: Dictionary = {}
    debugp("Instantiated dictionary")
    for level in Global.World.AllLevels:
        debugp("Auditing packs for " + level.Label + "[Layer " + level.ID + "]")
        debugp("Auditing tilemaps")

        var tilemap_textures = get_used_tile_textures(level)
        for tilemap_texture in tilemap_textures.values():
            var pack = identify_pack(tilemap_texture)
            append_pack_items(pack, "Tilemap", pack_list)
        
        debugp("Auditing walls")
        for wall in level.Walls.get_children():
            var pack = identify_pack(wall.Texture)
            append_pack_items(pack, "Wall", pack_list)
        
        debugp("Auditing portals")
        for wall in level.Walls.get_children():
            for portal in wall.get_children():
                if (get_texture(portal) != null):
                    var pack = identify_pack(get_texture(portal))
                    append_pack_items(pack, "Portal", pack_list)

        debugp("Auditing free-standing portals")
        for portal in level.Portals.get_children():
            var pack = identify_pack(get_texture(portal))
            append_pack_items(pack, "Portal", pack_list)

        debugp("Auditing Roofs")
        for roof in level.Roofs.get_children():
            var pack = identify_pack(get_texture(roof))
            append_pack_items(pack, "Roof", pack_list)
      
        debugp("Audit Pattern Shapes")
        for patternshape in level.PatternShapes.GetShapes():
            var pack = identify_pack(get_texture(patternshape))
            append_pack_items(pack, "PatternShape", pack_list)
        
        debugp("Audit Terrain Textures")
        # level.MaterialLookup is a SortedDictionary which will crash DD if we try to read from it,
        # so we used a roundabout method here.
        var materialLookup: Dictionary = level.SaveMaterialMeshes()
        for meshLayer in materialLookup.values():
            for mesh in meshLayer:
                var dummy_obj = {"resource_path": mesh.texture}
                var pack = identify_pack(dummy_obj)
                append_pack_items(pack, "TerrainTexture", pack_list)
        
        debugp("Audit Terrain Textures 2")
        for texture in level.Terrain.Textures:
            var pack = identify_pack(texture)
            append_pack_items(pack, "TerrainTexture", pack_list)

        debugp("Audit Paths")
        for pathway in level.Pathways.get_children():
            var pack = identify_pack(get_texture(pathway))
            append_pack_items(pack, "Pathway", pack_list)
    
        debugp("Audit Lights")
        for light in level.Lights.get_children():
            var pack = identify_pack(get_texture(light))
            append_pack_items(pack, "Light", pack_list)
    
    debugp("Auditing ObjectCensus")
    for texture in Global.Editor.owner.ObjectCensus.keys():
        debugp("GOT ONE")
        var pack = identify_pack(texture)
        pack["objType"] = "Unknown"
        if (not pack_list.has(pack["packID"])):
            pack_list[pack["packID"]] = []
        pack_list[pack["packID"]].append(pack)

    debugp(to_json(pack_list))
    return pack_list

func get_pack_use_count(audit_info):
    var count_dict: Dictionary = {}
    for pack in audit_info.keys():
        count_dict[pack] = {}
        for item in audit_info[pack]:
            count_dict[pack][item.texture] = null
        
        count_dict[pack] = len(count_dict[pack].keys())
    
    return count_dict

func load_infobox():
    if (Global.Editor.get_node("InfoboxRoot") == null):
        infobox = load(Global.Root + "ui/assetmanager_mod_infobox.tscn")
        infobox_instance = infobox.instance()
        infobox_instance.visible = false

        Global.Editor.add_child(infobox_instance, true)
        
        infobox_instance.get_node("VBoxContainer/DetailWindowButton").connect("pressed", self, "show_detailwindow")
    else:
        pass

func load_detailwindow():
    if (Global.Editor.get_node("AssetManagerDetailWindow") == null):
        dw = load(Global.Root + "ui/assetmanager_mod_detailwindow.tscn")
        dw_instance = dw.instance()
        Global.Editor.add_child(dw_instance, true)

        var opt_button: Button = dw_instance.get_node("MarginContainer/VBoxContainer/HBoxContainer/OptimiseButton")
        opt_button.connect("pressed", self, "deselect_unused")

        var apply: Button = dw_instance.get_node("MarginContainer/VBoxContainer/HBoxContainer/ApplyButton")
        apply.connect("pressed", self, "apply_pack_changes")
    else:
        pass

func toggle_asset_info(button_pressed: bool):
    debugp(Global.Editor.Windows["Assets"].packItems)
    infobox_visible = button_pressed

func show_detailwindow():
    dw_instance.popup_centered()
    update_detail_table()
    

func update_detail_table():
    # Audit packs
    pack_audit = audit_asset_packs()
    var pack_counts = get_pack_use_count(pack_audit)
    # Fetch reference to tree element
    var tree: Tree = dw_instance.get_node("MarginContainer/VBoxContainer/AssetPackInfo")
    tree.hide_root = true

    # Set column titles
    tree.clear()

    tree.set_column_expand(0, false)
    tree.set_column_expand(2, false)
    tree.set_column_expand(3, false)

    tree.set_column_title(1, "Pack")
    tree.set_column_title(2, "Version")
    tree.set_column_title(3, "Pack Object Instances")
    tree.set_column_title(4, "Unique Textures Used")
    tree.set_column_title(5, "Author")

    tree.set_column_titles_visible(true)

    tree.set_column_min_width(0, 32)
    tree.set_column_min_width(2, 72)
    tree.set_column_min_width(3, 224)

    var root_item = tree.create_item(null, -1)

    # Generate entries
    for entry in Global.Header.AssetManifest:
        var nItem = tree.create_item(root_item, -1)
        nItem.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
        nItem.set_checked(0, true)
        nItem.set_editable(0, true)

        nItem.set_text(1, entry.Name)
        nItem.set_text(2, entry.Version)
        nItem.set_text(3, len(pack_audit[entry.ID]) if pack_audit[entry.ID] != null else 0)
        nItem.set_text(4, pack_counts[entry.ID] if pack_audit[entry.ID] != null else 0)
        nItem.set_text(5, entry.Author)
        nItem.set_meta("packID", entry.ID)
        nItem.set_meta("auditInfo", pack_audit[entry.ID])

    var test = Global.Editor.Windows["MapInfo"]
    test._on_MapInfoWindow_about_to_show()
    print(test.packsUsed.text)

func deselect_unused():
    var tree: Tree = dw_instance.get_node("MarginContainer/VBoxContainer/AssetPackInfo")
    var tree_root = tree.get_root()
    
    var current_item = tree_root.get_children()

    while current_item != null:
        current_item.set_checked(0, current_item.get_text(4).to_int() > 0)
        current_item = current_item.get_next()

func apply_pack_changes():
    debugp("CALLED PACK CHANGES")
    var tree: Tree = dw_instance.get_node("MarginContainer/VBoxContainer/AssetPackInfo")
    var tree_root = tree.get_root()
    var asset_window = Global.Editor.Windows["Assets"]
    var asset_apply_button = asset_window.get_node("Margins/VAlign/Buttons/OkayButton");

    # Show and Hide Asset Window in background to ensure packItems is populated
    asset_window.popup_centered(Vector2(0, 0))

    debugp("Got tree")
    var new_asset_packs = []
    var new_asset_pack_ids = []
    
    var current_item = tree_root.get_children()

    while current_item != null:
        for item in asset_window.packItems:
            if item.get_meta("pack") == current_item.get_meta("packID"):
                debugp("MAtched")
                item.set_checked(0, current_item.is_checked())
        current_item = current_item.get_next()
    
    dw_instance.hide()
    asset_window.UpdateCheckAll()
    asset_apply_button.pressed = true
    asset_apply_button.pressed = false

# Utility function for retrieving prop textures
# Methods:
# - `prop.Texture`: `Wall`, `Object`, `Portal`
# - `prop.get_texture`: `Path`, `Light`
# - `prop._Texture`: `PatternShape`
# - `prop.TilesTexture`: `Roof`
func get_texture(prop: Node2D):
    var stool = Global.Editor.Tools["SelectTool"]
    match stool.GetSelectableType(prop):
        1, 2, 3, 4:
            return prop.Texture
        5, 6:
            return prop.get_texture()
        7:
            return prop._Texture
        8:
            return prop.TilesTexture
        _:
            return null
