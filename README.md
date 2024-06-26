# Aperos Voxel

Aperos Voxel is a voxel game inspired by Minecraft 
built in the Godot Engine v4.3.beta2 using the [godot_voxel](https://github.com/Zylann/godot_voxel) module.

It's currently in alpha phase and has various issues.

This project is based on [voxelgame](https://github.com/Zylann/voxelgame), and already features:

- World generation based on seed
- Random splashes on the initial menu
- Various block types
- Biome types (testing)
- In-game [debug information](https://github.com/godot-extended-libraries/godot-debug-menu) accessible by pressing F3. Press F3 twice for full details
- Inventory with icons (not automatically generated)
- Placing and breaking terrain blocks
- World limit of 536,870,911 in all directions
- World saving via stream (limited)

## TO-DO:

### Terrain
[ ] More comprehensive biome generation, considering temperature, erosion, and altitude

### Save
[ ] Saving worlds based on name, ID, and version

### Gameplay
[ ] Crafting system for items<br>
[ ] Life, hunger, and hydration system<br>
[ ] Limiting water spread across terrain<br>

### Lighting
[ ] Ambient lighting and voxel ambient occlusion, similar to Minecraft

## Contribution

You are welcome to contribute to the project by reporting bugs and unknown issues, 
or by submitting pull requests for fixes, implementations, textures, sounds, etc.
Please note that the project uses the `godot_voxel` module, so some issues may be module-specific. 
In the future, a fork of the module may be created for more specific management of Aperos Voxel.

When submitting a pull request, please adhere to the naming conventions for methods and variables, 
spacing between methods, etc.

Note: The project is using opengl3 as my humble laptop does not
runs well on Vulkan :<

**Texture**: [Excalibur](https://www.curseforge.com/minecraft/texture-packs/excalibur)
