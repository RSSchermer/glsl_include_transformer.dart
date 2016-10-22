import 'package:glsl_include_transformer/glsl_include_transformer.dart';
import 'package:test/test.dart';
import 'package:transformer_test/utils.dart';

void main() {
  group('GlslIncludeTransformer', () {
    testPhases('correctly substitutes an include with a relative URI', [
      [new GlslIncludeTransformer()]
    ], {
      'a|lib/shaders/a.glsl': '#include "partials/b.glsl"',
      'a|lib/shaders/partials/b.glsl': 'uniform vec3 test;'
    }, {
      'a|lib/shaders/a.glsl': 'uniform vec3 test;',
      'a|lib/shaders/partials/b.glsl': 'uniform vec3 test;'
    });

    testPhases('correctly substitutes an include with a packages URI', [
      [new GlslIncludeTransformer()]
    ], {
      'a|lib/shaders/a.glsl': '#include "../../../packages/b/shaders/b.glsl"',
      'b|lib/shaders/b.glsl': 'uniform vec3 test;'
    }, {
      'a|lib/shaders/a.glsl': 'uniform vec3 test;',
      'b|lib/shaders/b.glsl': 'uniform vec3 test;'
    });

    testPhases('correctly substitutes nested include directives', [
      [new GlslIncludeTransformer()]
    ], {
      'a|lib/shaders/a.glsl': '#include "b.glsl"',
      'a|lib/shaders/b.glsl': '#include "c.glsl"',
      'a|lib/shaders/c.glsl': 'uniform vec3 test;'
    }, {
      'a|lib/shaders/a.glsl': 'uniform vec3 test;',
      'a|lib/shaders/b.glsl': 'uniform vec3 test;',
      'a|lib/shaders/c.glsl': 'uniform vec3 test;'
    });

    testPhases('preserves the newlines around an include directive', [
      [new GlslIncludeTransformer()]
    ], {
      'a|lib/shaders/a.glsl': 'uniform float a;\n#include "partials/b.glsl"\nuniform float c;',
      'a|lib/shaders/partials/b.glsl': 'uniform float b;'
    }, {
      'a|lib/shaders/a.glsl': 'uniform float a;\nuniform float b;\nuniform float c;',
      'a|lib/shaders/partials/b.glsl': 'uniform float b;'
    });
  });
}
