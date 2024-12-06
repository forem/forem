(function(program, execJS) { execJS(program) })(function() { #{source}
}, function(program) {
  var output;
  try {
    delete this.console;
    delete this.setTimeout;
    delete this.setInterval;
    delete this.clearTimeout;
    delete this.clearInterval;
    delete this.setImmediate;
    delete this.clearImmediate;

    result = program();
    if (typeof result == 'undefined' && result !== null) {
      print('["ok"]');
    } else {
      try {
        print(JSON.stringify(['ok', result]));
      } catch (err) {
        print(JSON.stringify(['err', '' + err, err.stack]));
      }
    }
  } catch (err) {
    print(JSON.stringify(['err', '' + err, err.stack]));
  }
});
