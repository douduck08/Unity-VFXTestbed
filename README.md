### Shaders
#### Surface shader
* BaseColor
* ToonWater - A simple toon-style animated water shader
* Translucency - Adding translucency to blinnPhong lighting, forward path only.
* Standard Translucency - Adding translucency to standard lighting, need custom internal shader.

#### Unlit shader
* ScreenSpaceReflection - SSR with raymarching, which is implemented on single object but full screen post-process.

#### Internal shader
Used in `Graphic Settings > Built-in Shader Settings`, which is needed by `StandardTranslucency.shader`

### Houdini VAT experment
SideFX Lab version: 521

Three mode:
* rigid - fractured object movement
* soft - cloth simulate
* fluid - fluid simulate

### MeshGridDeform experment
Change the vertex position by a 2x2x2 grid in shader.

Prob
* Not so expensive on CPU side.
* More grids gain more flexibility.

Cons.
* Float array cannot be serilized.
* Cannot deform normal in correct direction.