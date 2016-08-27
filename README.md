# glsl_include_transformer.dart

Transformer preprocessor for `include` directives in `.glsl` shader files.

C-style `include` preprocessor directives then allow you to reuse source 
partials across multiple files. However, although OpenGL/WebGL implementations 
support most C-style preprocessor directives, `include` is a notable exception. 
This package adds support for `include` preprocessor directives through a Pub 
transformer that performs an additional preprocessing step at build time. 

## Usage

Add the `glsl_include_transformer` to the transformer list in your 
`pubspec.yaml`:

```yaml
transformers:
  - glsl_include_transformer
```

This transformer will substitute `include` directives in `.glsl` files with the 
contents of the file they reference:

```glsl
// Gets replaced with the contents of partials/my_shader_partial.glsl
#include "partials/my_shader_partial.glsl"

// Or alternatively, if you prefer angle brackets
#include <partials/my_shader_partial.glsl>
```

The `include` directive must reference a URI enclosed in double quotes or angle 
brackets. Unlike in C or C++ preprocessors there is no semantic difference 
between double quotes or angle brackets. The URI must be a relative URI 
(absolute URIs are not allowed):

```glsl
// my_package/lib/shaders/my_shader.glsl

// Includes my_package|lib/shaders/partials/some_shader_partial.glsl
#include "partials/some_shader_partial.glsl"
```

A URI may reach into another package via the packages directory:

```glsl
// my_package/lib/shaders/my_shader.glsl

// Includes some_package|lib/shaders/some_shader_partial.glsl
#include "../../packages/some_package/shaders/some_shader_partial.glsl"
```

You may only reference files in another package's `lib` directory. Note that 
URIs that reference another package should not contain a `lib` segment.
