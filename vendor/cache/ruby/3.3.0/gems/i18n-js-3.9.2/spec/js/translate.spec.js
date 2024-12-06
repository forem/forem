var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Translate", function(){
  var actual, expected;

  beforeEach(function(){
    I18n.reset();
    I18n.translations = Translations();
  });

  it("sets bound alias", function() {
    expect(I18n.t).toEqual(jasmine.any(Function));
    expect(I18n.t).not.toBe(I18n.translate);
  });

  it("returns translation for single scope", function(){
    expect(I18n.translate("hello")).toEqual("Hello World!");
  });

  it("returns translation with 't' shortcut", function(){
    var t = I18n.t;
    expect(t("hello")).toEqual("Hello World!");
  });

  it("returns translation as object", function(){
    expect(I18n.translate("greetings")).toEqual(I18n.translations.en.greetings);
  });

  it("returns missing message translation for valid scope with null", function(){
    actual = I18n.translate("null_key");
    expected = '[missing "en.null_key" translation]';
    expect(actual).toEqual(expected);
  });

  it("returns missing message translation for invalid scope", function(){
    actual = I18n.translate("invalid.scope");
    expected = '[missing "en.invalid.scope" translation]';
    expect(actual).toEqual(expected);
  });

  it("returns missing message translation with provided locale for invalid scope", function(){
    actual = I18n.translate("invalid.scope", { locale: "ja" });
    expected = '[missing "ja.invalid.scope" translation]';
    expect(actual).toEqual(expected);
  });

  it("returns guessed translation if missingBehaviour is set to guess", function(){
    I18n.missingBehaviour = 'guess'

    var actual_1 = I18n.translate("invalid.thisIsAutomaticallyGeneratedTranslation");
    var expected_1 = 'this is automatically generated translation';
    expect(actual_1).toEqual(expected_1);

    var actual_2 = I18n.translate("invalid.this_is_automatically_generated_translation");
    var expected_2 = 'this is automatically generated translation';
    expect(actual_2).toEqual(expected_2);
  });

  it("returns guessed translation with prefix if missingBehaviour is set to guess and prefix is also provided", function(){
    I18n.missingBehaviour = 'guess'
    I18n.missingTranslationPrefix = 'EE: '
    actual = I18n.translate("invalid.thisIsAutomaticallyGeneratedTranslation");
    expected = 'EE: this is automatically generated translation';
    expect(actual).toEqual(expected);
  });

  it("returns missing message translation for valid scope with scope", function(){
    actual = I18n.translate("monster", {scope: "greetings"});
    expected = '[missing "en.greetings.monster" translation]';
    expect(actual).toEqual(expected);
  });

  it("returns translation for single scope on a custom locale", function(){
    I18n.locale = "pt-BR";
    expect(I18n.translate("hello")).toEqual("Olá Mundo!");
  });

  it("returns translation for multiple scopes", function(){
    expect(I18n.translate("greetings.stranger")).toEqual("Hello stranger!");
  });

  it("returns translation with default locale option", function(){
    expect(I18n.translate("hello", {locale: "en"})).toEqual("Hello World!");
    expect(I18n.translate("hello", {locale: "pt-BR"})).toEqual("Olá Mundo!");
  });

  it("fallbacks to the default locale when I18n.fallbacks is enabled", function(){
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    expect(I18n.translate("greetings.stranger")).toEqual("Hello stranger!");
  });

  it("fallbacks to default locale when providing an unknown locale", function(){
    I18n.locale = "fr";
    I18n.fallbacks = true;
    expect(I18n.translate("greetings.stranger")).toEqual("Hello stranger!");
  });

  it("fallbacks to less specific locale", function(){
    I18n.locale = "de-DE";
    I18n.fallbacks = true;
    expect(I18n.translate("hello")).toEqual("Hallo Welt!");
  });

  describe("when a 3-part locale is used", function(){
    beforeEach(function(){
      I18n.locale = "zh-Hant-TW";
      I18n.fallbacks = true;
    });

    it("fallbacks to 2-part locale when absent", function(){
      expect(I18n.translate("cat")).toEqual("貓");
    });

    it("fallbacks to 1-part locale when 2-part missing requested translation", function(){
      expect(I18n.translate("dog")).toEqual("狗");
    });

    it("fallbacks to 2-part for the first time", function(){
      expect(I18n.translate("dragon")).toEqual("龍");
    });
  });

  it("fallbacks using custom rules (function)", function(){
    I18n.locale = "no";
    I18n.fallbacks = true;
    I18n.locales["no"] = function() {
      return ["nb"];
    };

    expect(I18n.translate("hello")).toEqual("Hei Verden!");
  });

  it("fallbacks using custom rules (array)", function() {
    I18n.locale = "no";
    I18n.fallbacks = true;
    I18n.locales["no"] = ["no", "nb"];

    expect(I18n.translate("hello")).toEqual("Hei Verden!");
  });

  it("fallbacks using custom rules (string)", function() {
    I18n.locale = "no";
    I18n.fallbacks = true;
    I18n.locales["no"] = "nb";

    expect(I18n.translate("hello")).toEqual("Hei Verden!");
  });

  describe("when provided default values", function() {
    it("uses scope provided in defaults if scope doesn't exist", function() {
      actual = I18n.translate("Hello!", {defaults: [{scope: "greetings.stranger"}]});
      expect(actual).toEqual("Hello stranger!");
    });

    it("continues to fallback until a scope is found", function() {
      var defaults = [{scope: "foo"}, {scope: "hello"}];

      actual = I18n.translate("foo", {defaults: defaults});
      expect(actual).toEqual("Hello World!");
    });

    it("uses message if specified as a default", function() {
      var defaults = [{message: "Hello all!"}];
      actual = I18n.translate("foo", {defaults: defaults});
      expect(actual).toEqual("Hello all!");
    });

    it("uses the first message if no scopes are found", function() {
      var defaults = [
          {scope: "bar"}
        , {message: "Hello all!"}
        , {scope: "hello"}];
      actual = I18n.translate("foo", {defaults: defaults});
      expect(actual).toEqual("Hello all!");
    });

    it("uses default value if no scope is found", function() {
      var options = {
          defaults: [{scope: "bar"}]
        , defaultValue: "Hello all!"
      };
      actual = I18n.translate("foo", options);
      expect(actual).toEqual("Hello all!");
    });

    it("uses default scope over default value if default scope is found", function() {
      var options = {
          defaults: [{scope: "hello"}]
        , defaultValue: "Hello all!"
      };
      actual = I18n.translate("foo", options);
      expect(actual).toEqual("Hello World!");
    })

    it("uses default value with lazy evaluation", function () {
      var options = {
          defaults: [{scope: "bar"}]
        , defaultValue: function(scope) {
          return scope.toUpperCase();
        }
      };
      actual = I18n.translate("foo", options);
      expect(actual).toEqual("FOO");
    })

    it("pluralizes using the correct scope if translation is found within default scope", function() {
      expect(I18n.translations["en"]["mailbox"]).toEqual(undefined);
      actual = I18n.translate("mailbox.inbox", {count: 1, defaults: [{scope: "inbox"}]});
      expected = I18n.translate("inbox", {count: 1})
      expect(actual).toEqual(expected)
    })
  });

  it("uses default value for simple translation", function(){
    actual = I18n.translate("warning", {defaultValue: "Warning!"});
    expect(actual).toEqual("Warning!");
  });

  it("uses default value for plural translation", function(){
    actual = I18n.translate("message", {defaultValue: { one: '%{count} message', other: '%{count} messages'}, count: 1});
    expect(actual).toEqual("1 message");
  });

  it("uses default value for unknown locale", function(){
    I18n.locale = "fr";
    actual = I18n.translate("warning", {defaultValue: "Warning!"});
    expect(actual).toEqual("Warning!");
  });

  it("uses default value with interpolation", function(){
    actual = I18n.translate(
      "alert",
      {defaultValue: "Attention! {{message}}", message: "You're out of quota!"}
    );

    expect(actual).toEqual("Attention! You're out of quota!");
  });

  it("ignores default value when scope exists", function(){
    actual = I18n.translate("hello", {defaultValue: "What's up?"});
    expect(actual).toEqual("Hello World!");
  });

  it("returns translation for custom scope separator", function(){
    I18n.defaultSeparator = "•";
    actual = I18n.translate("greetings•stranger");
    expect(actual).toEqual("Hello stranger!");
  });

  it("returns boolean values", function() {
    expect(I18n.translate("booleans.yes")).toEqual(true);
    expect(I18n.translate("booleans.no")).toEqual(false);
  });

  it("escapes $ when doing substitution (IE)", function(){
    I18n.locale = "en";

    expect(I18n.translate("paid", {price: "$0"})).toEqual("You were paid $0");
    expect(I18n.translate("paid", {price: "$0.12"})).toEqual("You were paid $0.12");
    expect(I18n.translate("paid", {price: "$1.35"})).toEqual("You were paid $1.35");
  });

  it("replaces all occurrences of escaped $", function(){
    I18n.locale = "en";

    expect(I18n.translate("paid_with_vat", {
      price: "$0.12",
      vat: "$0.02"}
    )).toEqual("You were paid $0.12 (incl. VAT $0.02)");
  });

  it("sets default scope", function(){
    var options = {scope: "greetings"};
    expect(I18n.translate("stranger", options)).toEqual("Hello stranger!");
  });

  it("accepts the scope as an array", function(){
    expect(I18n.translate(["greetings", "stranger"])).toEqual("Hello stranger!");
  });

  it("accepts the scope as an array using a base scope", function(){
    expect(I18n.translate(["stranger"], {scope: "greetings"})).toEqual("Hello stranger!");
  });

  it("returns an array with values interpolated", function(){
    var options = {value: 314};
    expect(I18n.translate("arrayWithParams", options)).toEqual([
      null,
      "An item with a param of " + options.value,
      "Another item with a param of " + options.value,
      "A last item with a param of " + options.value,
      ["An", "array", "of", "strings"],
      {foo: "bar"}
    ]);
  });


  it("returns value with key containing dot but different separator specified", function() {
    expect(I18n.t(["A implies B means something."], {scope: "sentences_with_dots", separator: "|"})).toEqual("A implies B means that when A is true, B must be true.");
  });
});
