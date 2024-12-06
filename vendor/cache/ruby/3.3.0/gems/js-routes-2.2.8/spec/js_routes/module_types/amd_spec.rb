require "spec_helper"

describe JsRoutes, "compatibility with AMD/require.js"  do

  before(:each) do
    evaljs("var global = this;", force: true)
    evaljs("global.GlobalCheck = {};")
    evaljs("global.define = function (requirs, callback) { global.GlobalCheck['js-routes'] = callback.call(this); return global.GlobalCheck['js-routes']; };")
    evaljs("global.define.amd = { jQuery: true };")
    strRequire =<<EOF
    global.require = function (r, callback) {
      var allArgs, i;

      allArgs = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = r.length; _i < _len; _i++) {
          i = r[_i];
          _results.push(global.GlobalCheck[i]);
        }
        return _results;
      })();

      return callback.apply(null, allArgs);
    };
EOF
    evaljs(strRequire)
    evaljs(JsRoutes.generate(module_type: 'AMD'))
  end

  it "should working from require" do
    expectjs("require(['js-routes'], function(r){ return r.inboxes_path(); })").to eq(test_routes.inboxes_path())
  end

end
