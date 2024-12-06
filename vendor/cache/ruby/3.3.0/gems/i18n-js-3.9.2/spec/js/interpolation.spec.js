var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Interpolation", function(){
  var actual, expected;

  beforeEach(function(){
    I18n.reset();
    I18n.translations = Translations();
  });

  it("performs single interpolation", function(){
    actual = I18n.t("greetings.name", {name: "John Doe"});
    expect(actual).toEqual("Hello John Doe!");
  });

  it("performs multiple interpolations", function(){
    actual = I18n.t("profile.details", {name: "John Doe", age: 27});
    expect(actual).toEqual("John Doe is 27-years old");
  });

  describe("Pluralization", function() {
    var translation_key;

    describe("when count is passed in", function() {
      describe("and translation key does contain pluralization", function() {
        beforeEach(function() {
          translation_key = "inbox";
        });

        it("return translated and pluralized string", function() {
          expect(I18n.t(translation_key, {count: 0})).toEqual("You have no messages");
          expect(I18n.t(translation_key, {count: 1})).toEqual("You have 1 message");
          expect(I18n.t(translation_key, {count: 5})).toEqual("You have 5 messages");
        });
      });
      describe("and translation key does NOT contain pluralization", function() {
        beforeEach(function() {
          translation_key = "hello";
        });

        it("return translated string ONLY", function() {
          expect(I18n.t(translation_key, {count: 0})).toEqual("Hello World!");
          expect(I18n.t(translation_key, {count: 1})).toEqual("Hello World!");
          expect(I18n.t(translation_key, {count: 5})).toEqual("Hello World!");
        });
      });
      describe("and translation key does contain pluralization with null content", function() {
        beforeEach(function() {
          translation_key = "sent";
        });

        it("return empty string", function() {
          expect(I18n.t(translation_key, {count: 0})).toEqual('[missing "en.sent.zero" translation]');
          expect(I18n.t(translation_key, {count: 1})).toEqual('[missing "en.sent.one" translation]');
          expect(I18n.t(translation_key, {count: 5})).toEqual('[missing "en.sent.other" translation]');
        });
      });
    });

    describe("when count is NOT passed in", function() {
      describe("and translation key does contain pluralization", function() {
        beforeEach(function() {
          translation_key = "inbox";
        });

        var expected_translation_object = {
          one : 'You have {{count}} message',
          other : 'You have {{count}} messages',
          zero : 'You have no messages'
        }

        it("return translated and pluralized string", function() {
          expect(I18n.t(translation_key, {not_count: 0})).toEqual(expected_translation_object);
          expect(I18n.t(translation_key, {not_count: 1})).toEqual(expected_translation_object);
          expect(I18n.t(translation_key, {not_count: 5})).toEqual(expected_translation_object);
        });
      });
      describe("and translation key does NOT contain pluralization", function() {
        beforeEach(function() {
          translation_key = "hello";
        });

        it("return translated string ONLY", function() {
          expect(I18n.t(translation_key, {not_count: 0})).toEqual("Hello World!");
          expect(I18n.t(translation_key, {not_count: 1})).toEqual("Hello World!");
          expect(I18n.t(translation_key, {not_count: 5})).toEqual("Hello World!");
        });
      });
    });
  });

  it("outputs missing placeholder message if interpolation value is missing", function(){
    actual = I18n.t("greetings.name");
    expect(actual).toEqual("Hello [missing {{name}} value]!");
  });

  it("outputs missing placeholder message if interpolation value is null", function(){
    actual = I18n.t("greetings.name", {name: null});
    expect(actual).toEqual("Hello [missing {{name}} value]!");
  });

  it("allows overriding the null placeholder message", function(){
    var orig = I18n.nullPlaceholder;
    I18n.nullPlaceholder = function() {return "";}
    actual = I18n.t("greetings.name", {name: null});
    expect(actual).toEqual("Hello !");
    I18n.nullPlaceholder = orig;
  });

  it("provides missingPlaceholder with the placeholder, message, and options object", function(){
    var orig = I18n.missingPlaceholder;
    I18n.missingPlaceholder = function(placeholder, message, options) {
      expect(placeholder).toEqual('{{name}}');
      expect(message).toEqual('Hello {{name}}!');
      expect(options.debugScope).toEqual('landing-page');
      return '[missing-placeholder-debug]';
    };
    actual = I18n.t("greetings.name", {debugScope: 'landing-page'});
    expect(actual).toEqual("Hello [missing-placeholder-debug]!");
    I18n.missingPlaceholder = orig;
  });
});
