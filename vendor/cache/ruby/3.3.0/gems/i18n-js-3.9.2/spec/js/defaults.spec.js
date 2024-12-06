var I18n = require("../../app/assets/javascripts/i18n");

describe("Defaults", function(){
  beforeEach(function(){
    I18n.reset();
  });

  it("sets the default locale", function(){
    expect(I18n.defaultLocale).toEqual("en");
  });

  it("sets current locale", function(){
    expect(I18n.locale).toEqual("en");
  });

  it("sets default separator", function(){
    expect(I18n.defaultSeparator).toEqual(".");
  });

  it("sets fallback", function(){
    expect(I18n.fallbacks).toEqual(false);
  });

  it("set empty translation prefix", function(){
    expect(I18n.missingTranslationPrefix).toEqual('');
  });

  it("sets default missingBehaviour", function(){
    expect(I18n.missingBehaviour).toEqual('message');
  });
});
