AnimatedWallpaperTest
=====================

Custom dynamic wallpapers on iOS 7:


Dynamic wallpapers are stored in bundles which get loaded into SpringBoard, located at /System/Library/ProceduralWallpaper.


A bundle declares the class name for each dynamic wallpaper it contains via the key “SBProceduralWallpaperClassNames” in its Info.plist file (The expected value for that key is an array, so bundles can contain multiple dynamic wallpapers)


Each class representing a dynamic wallpaper must conform to the “SBFProceduralWallpaper” protocol, which is declared in a private framework called “SpringBoardFoundation”. The view returned via this protocol is what is actually displayed on screen. For convenience, SpringBoardFoundation contains a class called “SBFProceduralWallpaper”: a UIView subclass which returns itself for the view to be displayed.

Implementing this in OpenGL may have been slightly overkill, oh well...
