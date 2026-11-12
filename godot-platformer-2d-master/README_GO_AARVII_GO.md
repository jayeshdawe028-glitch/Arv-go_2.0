# Go Aarvii Go ! - final project (Godot 3)

Open: game/project.godot  (first open takes a minute: Godot imports the new music/images)

## Replace things later
- Title screen picture : game/assets/branding/title_art.png   (same name, any size)
- Company splash logo  : game/assets/branding/bonina_logo.png  (shown ~3 sec at startup)
- Sky in the levels    : game/assets/environment/background/sky.png
- App icon             : game/icon.png  (512x512)
- Death sounds         : game/assets/audio/death_1.mp3, death_2.mp3
- Music                : game/assets/audio/music_menu.ogg, music_game.ogg
- Colors / buttons     : game/src/UI/UITheme.gd
- Game title text      : game/src/UI/MainMenu.gd (top constants)

## Startup splash
- game/src/UI/SplashScreen.tscn is now the first scene: Bonina logo on black,
  fade in 0.7s + hold 1.6s + fade out 0.7s (~3 sec), then the main menu opens.
- Timings are the FADE_IN / HOLD / FADE_OUT constants in game/src/UI/SplashScreen.gd.

## How it works
- Progress is saved in user://aarvii_save.json (Continue / New Game / Select Level)
- Level 1, 2 = original hand-made levels. Levels 3-50 = src/Levels/LevelGenerator.gd (always completable, harder each level)
- Cats: src/AI/*.tscn, drawn by src/Player/Rectangle.gd (cat_style)
