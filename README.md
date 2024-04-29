# DartOpenGL
The project is a composition of Dart and OpenGL applications ranging from Neuromorphic to Games

# Create new project
You can create a new project via Flutter. Using *dart*

```sh
dart create basic_template
```

# Json launch entry
Note: you need to update the "program" to reference the appropriate target.
```json
{
    "name": "DartRunner",
    "cwd": "/home/iposthuman/Documents/dart/DartOpenGL/",
    "program": "basic_template/bin/main.dart",
    "request": "launch",
    "type": "dart"
},
```

# GLFW
Which version is installed:
```sh
pkg-config --list-all |grep -i glfw
```

finding .so library file:
```sh
ldconfig -p | grep libglfw
```
Produces:
```
libglfw.so.3 (libc6,x86-64) => /lib/x86_64-linux-gnu/libglfw.so.3
```

Next create a link.

Creating link to libglfw3.so:
```sh
ln -s /lib/x86_64-linux-gnu/libglfw.so.3 /usr/local/lib/libglfw.so
```

Then add a path var.

Adding an entry to settings.json didn't seem to work:
```json
"dart.env": {
    "name": "LD_LIBRARY_PATH", "value": "/usr/local/lib/"
}
```

However, adding an entry to my .bashrc file did:
```sh
export LD_LIBRARY_PATH="/usr/local/lib"
```
And then ```source .bashrc`` and restarting vscode worked.
