### Shaders
#### Surface shader
* BaseColor
* ToonWater - A simple toon-style animated water shader
* Translucency - Adding translucency to blinnPhong lighting, forward path only.
* StandardSSS - Adding translucency to standard lighting, need custom internal shader.

#### Unlit shader
* ScreenSpaceReflection - SSR with raymarching, which is implemented on single object but full screen post-process.

#### Internal shader
Used in `Graphic Settings > Built-in Shader Settings`, which is needed by `StandardSSS.shader`

### Houdini VAT experment
SideFX Lab version: 521