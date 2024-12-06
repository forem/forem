var I18n = require("../../app/assets/javascripts/i18n");

describe("Utility Functions", function(){
  beforeEach(function(){
    I18n.reset();
  });

  describe("I18n.lookup", function() {
    it("does not change locale on failed lookup", function(){
      var fallback_locales = ['fallback1', 'fallback2'];

      I18n.locales['lang'] = fallback_locales.slice();
      expect(I18n.locales.lang).toEqual(fallback_locales);

      I18n.lookup('anything', {locale: 'lang'})
      expect(I18n.locales.lang).toEqual(fallback_locales);
    });

  })
});
