/// Transformer preprocessor for include directives in `.glsl` shader files.
library glsl_include_transformer;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:code_transformers/assets.dart';
import 'package:source_span/source_span.dart';

/// Transforms `include` preprocessor directives in `.glsl` files.
///
/// Substitutes `include` directive in `.glsl` files with the contents of the
/// file they reference:
///
///     // Gets replaced with the contents of partials/my_shader_partial.glsl
///     #include "partials/my_shader_partial.glsl"
///
///     // Or alternatively, if you prefer angle brackets
///     #include <partials/my_shader_partial.glsl>
///
/// The `include` directive must reference a URI enclosed in double quotes or
/// angle brackets. Unlike in C or C++ preprocessors there is no semantic
/// difference between double quotes or angle brackets. The URI must be a
/// relative URI (absolute URIs are not allowed):
///
///     // my_package/lib/shaders/my_shader.glsl
///
///     // Includes my_package|lib/shaders/partials/some_shader_partial.glsl
///     #include "partials/some_shader_partial.glsl"
///
/// A URI may reach into another package via the packages directory:
///
///     // Includes some_package|lib/shaders/some_shader_partial.glsl
///     #include "../../packages/some_package/shaders/some_shader_partial.glsl"
///
/// You may only reference files in another package's `lib` directory. Note that
/// URIs that reference another package should not contain a `lib` segment.
class GlslIncludeTransformer extends Transformer {
  final RegExp _pattern = new RegExp(r"""\s*#\s*include\s+["\<](.*)["\>]\s*""");

  GlslIncludeTransformer();

  GlslIncludeTransformer.asPlugin();

  String get allowedExtensions => '.glsl';

  Future apply(Transform transform) async {
    final logger = new BuildLogger(transform);
    final id = transform.primaryInput.id;
    final newContents = await _buildSource(id, transform, logger);

    transform.addOutput(new Asset.fromString(id, newContents));
  }

  Future<String> _buildSource(
      AssetId assetId, Transform transform, BuildLogger logger) async {
    final contents = await transform.readInputAsString(assetId);

    return _replaceAllMappedAsync(contents, _pattern, (match) async {
      final spanStart = match.start + match[0].indexOf('#');
      final spanEnd = match.end;
      final sourceSpan =
          new SourceFile(contents, url: assetId.path).span(spanStart, spanEnd);
      final includedId = uriToAssetId(assetId, match[1], logger, sourceSpan);

      if (!await transform.hasInput(includedId)) {
        logger.warning(
            'Could not find asset '
            '${includedId.package}|${includedId.path}, include directive '
            'skipped.',
            span: sourceSpan);

        return match[0];
      } else {
        return _buildSource(includedId, transform, logger);
      }
    });
  }
}

Future<String> _replaceAllMappedAsync(
    String string, Pattern exp, Future<String> replace(Match match)) async {
  final replaced = new StringBuffer();
  var currentIndex = 0;

  for (var match in exp.allMatches(string)) {
    var prefix = match.input.substring(currentIndex, match.start);

    currentIndex = match.end;

    replaced..write(prefix)..write(await replace(match));
  }

  replaced.write(string.substring(currentIndex));

  return replaced.toString();
}
