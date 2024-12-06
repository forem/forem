var I18n = require("../../app/assets/javascripts/i18n");

describe("Locales", function(){
  beforeEach(function(){
    I18n.reset();
  });

  it("returns the requested locale, if available", function(){
    I18n.locales["ab"] = ["ab"];
    expect(I18n.locales.get("ab")).toEqual(["ab"]);
  });

  it("wraps single results in an array", function(){
    I18n.locales["cd"] = "cd";
    expect(I18n.locales.get("cd")).toEqual(["cd"]);
  });

  it("returns the result of locale functions", function(){
    I18n.locales["fn"] = function() {
      return "gg";
    };
    expect(I18n.locales.get("fn")).toEqual(["gg"]);
  });

  it("uses I18n.locale as a fallback", function(){
    I18n.locale = "xx";
    I18n.locales["xx"] = ["xx"];
    expect(I18n.locales.get()).toEqual(["xx"]);
    expect(I18n.locales.get("yy")).toEqual(["xx"]);
  });
});
