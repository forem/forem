(function(program, execJS) { (function() {execJS(program) }).call({}); })(function(self, global, process, module, exports, require, console, setTimeout, setInterval, clearTimeout, clearInterval, setImmediate, clearImmediate) { #{source}
}, function(program) {
  // Force BunJS to use sloppy mode see https://github.com/oven-sh/bun/issues/4527#issuecomment-1709520894
  exports.abc = function(){}
  var __process__ = process;
  var printFinal = function(string) {
    process.stdout.write('' + string, function() {
      __process__.exit(0);
    });
  };
  try {
    delete this.process;
    delete this.console;
    result = program();
    process = __process__;
    if (typeof result == 'undefined' && result !== null) {
      printFinal('["ok"]');
    } else {
      try {
        printFinal(JSON.stringify(['ok', result]));
      } catch (err) {
        printFinal(JSON.stringify(['err', '' + err, err.stack]));
      }
    }
  } catch (err) {
    process = __process__;
    printFinal(JSON.stringify(['err', '' + err, err.stack]));
  }
});
