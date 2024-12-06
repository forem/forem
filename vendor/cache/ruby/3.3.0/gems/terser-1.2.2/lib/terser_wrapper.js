// Set source-map.js sourceMap to terser.js MOZ_SourceMap
MOZ_SourceMap = sourceMap;

var global = global || {};

function comments(option) {
  if (Object.prototype.toString.call(option) === '[object Array]') {
    return new RegExp(option[0], option[1]);
  } else if (option == "jsdoc") {
    return function(node, comment) {
      if (comment.type == "comment2") {
        return /@preserve|@license|@cc_on/i.test(comment.value);
      } else {
        return false;
      }
    };
  } else {
    return option;
  }
}

function regexOption(options) {
  if (typeof options === 'object' && options.regex) {
    return new RegExp(options.regex[0], options.regex[1]);
  } else {
    return null;
  }
}

function terser_wrapper(options) {
  var source = options.source;
  options.output.comments = comments(options.output.comments);

  if (options.mangle) {
    if (options.mangle.properties) {
      options.mangle.properties.regex = regexOption(options.mangle.properties);
    }
  }
  delete options.source;


  var inputFilename = '0';
  if (options.sourceMap) {
    inputFilename = options.sourceMap.input;
    delete options.sourceMap.input;
  }

  var inputs = {};
  inputs[inputFilename] = source;

  try {
    return Terser.minify_sync(inputs, options, null);
  } catch (error) {
    const { message, filename, line, col, pos } = error;
    return {error: {message: message, filename: filename, line: line, col: col, pos: pos}}
  }
}
