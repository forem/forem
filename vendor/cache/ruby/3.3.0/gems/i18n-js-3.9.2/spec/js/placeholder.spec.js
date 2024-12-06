var I18n = require("../../app/assets/javascripts/i18n");

describe("Placeholder", function(){
  beforeEach(function(){
    I18n.reset();
  });

  it("matches {{name}}", function(){
    expect("{{name}}").toMatch(I18n.placeholder);
  });

  it("matches %{name}", function(){
    expect("%{name}").toMatch(I18n.placeholder);
  });

  it("returns placeholders", function(){
    var translation = "I like %{javascript}. I also like %{ruby}"
      , matches = translation.match(I18n.placeholder);
    ;

    expect(matches[0]).toEqual("%{javascript}");
    expect(matches[1]).toEqual("%{ruby}");
  });
});
