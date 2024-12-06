var I18n = require("../../app/assets/javascripts/i18n");

describe("Current locale", function(){
  beforeEach(function(){
    I18n.reset();
  });

  it("returns I18n.locale", function(){
    I18n.locale = "pt-BR";
    expect(I18n.currentLocale()).toEqual("pt-BR");
  });

  it("returns I18n.defaultLocale", function(){
    I18n.locale = null;
    I18n.defaultLocale = "pt-BR";

    expect(I18n.currentLocale()).toEqual("pt-BR");
  });
});
