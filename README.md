A collection of tools for Dungeondraft 1.1.0.0+.

Current functionality includes an eyedropper for assets, alignment tools and “Select Similar” functionality

## Eyedropper Tool / Picker
Allows quick selection of anything on the map, and automatically switches to the relevant tool. You can quickly change to the picker tool by pressing P

## Known Limitations:
– Using the Picker on Roofs will correctly set the Roof type, but this will not be reflected in the UI
– When zoomed out, Light elements can sometimes be selected even when it appears it shouldn’t be. This is a limitation that I currently can’t work around
– The shortcut P currently isn’t rebindable, I may add that later

## Alignment Tools
Allows quick alignment of any selection made up of lights, objects and freestanding doors.

### Notes:
– The first thing you select will be what all other selections align too
– The alignment buttons will be disabled if your selection includes an item that can’t be aligned

### Known Limitations:
– Alignment to edges of objects can be unreliable if objects in the selection aren’t rotated at angles a multiple of 90 degrees
– Changes made using the alignment tool cannot be undone. This is a limitation of the modding API, and unless Megasploot exposes their HistoryRecord classes to GDScript, I can’t fix it

## Select Similar
Allows for quick selection of all cosmetically similar items on map. Selection criteria is listed below.

### Selection Criteria:
– Portals: Texture
– Objects: Texture, Color
– Paths: Texture
– Walls: Texture, Color
– Pattern Shapes: Texture, Color and Rotation
– Lights: Texture
– Roofs: Texture and Roof Type