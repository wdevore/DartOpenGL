# DartOpenGL
The project is a composition of Dart and OpenGL applications ranging from Neuromorphic to Games. It uses GLFW.

# learnopengl.com for Dart
Contains code samples for all chapters of Learn OpenGL and [https://learnopengl.com](https://learnopengl.com). 

# TODOs
- Correctly define vertex winding to Face culling can be enabled.

# Create new project
You can create a new project via Flutter. Using *dart*

```sh
dart create basic_template
```

You can also copy an existing basic project by:
- Copy and rename project
- Update yaml *name:* attribute to match project name
- In *main.dart* update glfwCreateWindow name to match yaml
- Update any dependent shader loading names
- Update *launch.json* and modify the **DartRunner** "program" entry key to point to the new path. See below **Json launch entry** section.
- Restart vscode because it will be out of sync

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
