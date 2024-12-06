var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Pluralization", function(){
  var actual, expected;

  beforeEach(function(){
    I18n.reset();
    I18n.translations = Translations();
  });

  it("sets bound alias", function() {
    expect(I18n.p).toEqual(jasmine.any(Function));
    expect(I18n.p).not.toBe(I18n.pluralize);
  });

  it("pluralizes scope", function(){
    expect(I18n.p(0, "inbox")).toEqual("You have no messages");
    expect(I18n.p(1, "inbox")).toEqual("You have 1 message");
    expect(I18n.p(5, "inbox")).toEqual("You have 5 messages");
  });

  it("pluralizes scope with 'p' shortcut", function(){
    var p = I18n.p;
    expect(p(0, "inbox")).toEqual("You have no messages");
    expect(p(1, "inbox")).toEqual("You have 1 message");
    expect(p(5, "inbox")).toEqual("You have 5 messages");
  });

  it("pluralizes using the 'other' scope", function(){
    I18n.translations["en"]["inbox"]["zero"] = null;
    expect(I18n.p(0, "inbox")).toEqual("You have 0 messages");
  });

  it("pluralizes using the 'zero' scope", function(){
    I18n.translations["en"]["inbox"]["zero"] = "No messages (zero)";

    expect(I18n.p(0, "inbox")).toEqual("No messages (zero)");
  });

  it("pluralizes using negative values", function(){
    expect(I18n.p(-1, "inbox")).toEqual("You have -1 messages");
    expect(I18n.p(-5, "inbox")).toEqual("You have -5 messages");
  });

  it("returns missing translation", function(){
    expect(I18n.p(-1, "missing")).toEqual('[missing "en.missing" translation]');
  });

  it("pluralizes using multiple placeholders", function(){
    actual = I18n.p(1, "unread", {unread: 5});
    expect(actual).toEqual("You have 1 new message (5 unread)");

    actual = I18n.p(10, "unread", {unread: 2});
    expect(actual).toEqual("You have 10 new messages (2 unread)");

    actual = I18n.p(0, "unread", {unread: 5});
    expect(actual).toEqual("You have no new messages (5 unread)");
  });

  it("allows empty strings", function(){
    I18n.translations["en"]["inbox"]["zero"] = "";

    expect(I18n.p(0, "inbox")).toEqual("");
  });

  it("returns missing message on null values", function(){
    I18n.translations["en"]["sent"]["zero"]  = null;
    I18n.translations["en"]["sent"]["one"]   = null;
    I18n.translations["en"]["sent"]["other"] = null;

    expect(I18n.p(0, "sent")).toEqual('[missing "en.sent.zero" translation]');
    expect(I18n.p(1, "sent")).toEqual('[missing "en.sent.one" translation]');
    expect(I18n.p(5, "sent")).toEqual('[missing "en.sent.other" translation]');
  });

  it("pluralizes using custom rules", function() {
    I18n.locale = "custom";

    I18n.pluralization["custom"] = function(count) {
      if (count === 0) { return ["zero"]; }
      if (count >= 1 && count <= 5) { return ["few", "other"]; }
      return ["other"];
    };

    I18n.translations["custom"] = {
      "things": {
          "zero": "No things"
        , "few": "A few things"
        , "other": "%{count} things"
      }
    }

    expect(I18n.p(0, "things")).toEqual("No things");
    expect(I18n.p(4, "things")).toEqual("A few things");
    expect(I18n.p(-4, "things")).toEqual("-4 things");
    expect(I18n.p(10, "things")).toEqual("10 things");
  });

  it("pluralizes default value", function(){
    options = {defaultValue: {
        zero: "No things here!"
      , one: "There is {{count}} thing here!"
      , other: "There are {{count}} things here!"
    }};

    expect(I18n.p(0, "things", options)).toEqual("No things here!");
    expect(I18n.p(1, "things", options)).toEqual("There is 1 thing here!");
    expect(I18n.p(5, "things", options)).toEqual("There are 5 things here!");
  });

  it("ignores pluralization when scope exists", function(){
    options = {defaultValue: {
        zero: "No things here!"
      , one: "There is {{count}} thing here!"
      , other: "There are {{count}} things here!"
    }};

    expect(I18n.p(0, "inbox", options)).toEqual("You have no messages");
    expect(I18n.p(1, "inbox", options)).toEqual("You have 1 message");
    expect(I18n.p(5, "inbox", options)).toEqual("You have 5 messages");
  });

  it("fallback to default locale when I18n.fallbacks is enabled", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["pt-BR"].inbox= {
        one: null
      , other: null
      , zero: null
    };
    expect(I18n.p(0, "inbox", { count: 0 })).toEqual("You have no messages");
    expect(I18n.p(1, "inbox", { count: 1 })).toEqual("You have 1 message");
    expect(I18n.p(5, "inbox", { count: 5 })).toEqual("You have 5 messages");
  });

  it("fallback to default locale when I18n.fallbacks is enabled", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["pt-BR"].inbox= {
        one: "Você tem uma mensagem"
      , other: null
      , zero: "Você não tem nenhuma mensagem"
    };
    expect(I18n.p(0, "inbox", { count: 0 })).toEqual("Você não tem nenhuma mensagem");
    expect(I18n.p(1, "inbox", { count: 1 })).toEqual("Você tem uma mensagem");
    expect(I18n.p(5, "inbox", { count: 5 })).toEqual('You have 5 messages');
  });

  it("fallback to default locale when I18n.fallbacks is enabled and value is null", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["pt-BR"].inbox = null;
    expect(I18n.p(0, "inbox", { count: 0 })).toEqual("You have no messages");
    expect(I18n.p(1, "inbox", { count: 1 })).toEqual("You have 1 message");
    expect(I18n.p(5, "inbox", { count: 5 })).toEqual("You have 5 messages");
  });

  it("fallback to 'other' scope", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["pt-BR"].inbox= {
        one: "Você tem uma mensagem"
      , other: "Você tem {{count}} mensagens"
      , zero: null
    }
    expect(I18n.p(0, "inbox", { count: 0 })).toEqual("Você tem 0 mensagens");
    expect(I18n.p(1, "inbox", { count: 1 })).toEqual("Você tem uma mensagem");
    expect(I18n.p(5, "inbox", { count: 5 })).toEqual("Você tem 5 mensagens");
  });

  it("fallback to defaulValue when defaultValue is string", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["en"]["inbox"]["zero"]  = null;
    I18n.translations["en"]["inbox"]["one"]   = null;
    I18n.translations["en"]["inbox"]["other"] = null;
    I18n.translations["pt-BR"].inbox= {
        one: "Você tem uma mensagem"
      , other: null
      , zero: null
    }
    options = {
      defaultValue: "default message"
    };
    expect(I18n.p(0, "inbox", options)).toEqual("default message");
    expect(I18n.p(1, "inbox", options)).toEqual("Você tem uma mensagem");
    expect(I18n.p(5, "inbox", options)).toEqual("default message");
  });

  it("fallback to defaulValue when defaultValue is an object", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["en"]["inbox"]["zero"]  = null;
    I18n.translations["en"]["inbox"]["one"]   = null;
    I18n.translations["en"]["inbox"]["other"] = null;
    I18n.translations["pt-BR"].inbox= {
        one: "Você tem uma mensagem"
      , other: null
      , zero: null
    }
    options = {
      defaultValue: {
        zero: "default message for no message"
        , one: "default message for 1 message"
        , other: "default message for {{count}} messages"
      }
    };
    expect(I18n.p(0, "inbox", options)).toEqual("default message for no message");
    expect(I18n.p(1, "inbox", options)).toEqual("Você tem uma mensagem");
    expect(I18n.p(5, "inbox", options)).toEqual("default message for 5 messages");
  });

  it("fallback to default locale when I18n.fallbacks is enabled and no translations in sub scope", function() {
    I18n.locale = "pt-BR";
    I18n.fallbacks = true;
    I18n.translations["en"]["mailbox"] = {
      inbox: I18n.translations["en"].inbox
    }

    expect(I18n.translations["pt-BR"]["mailbox"]).toEqual(undefined);
    expect(I18n.p(0, "mailbox.inbox", { count: 0 })).toEqual("You have no messages");
    expect(I18n.p(1, "mailbox.inbox", { count: 1 })).toEqual("You have 1 message");
    expect(I18n.p(5, "mailbox.inbox", { count: 5 })).toEqual("You have 5 messages");
  });

});
