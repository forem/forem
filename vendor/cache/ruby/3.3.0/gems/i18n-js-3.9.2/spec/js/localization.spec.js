var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Localization", function(){
  var actual, expected;

  beforeEach(function() {
    I18n.reset();
    I18n.translations = Translations();
  });

  it("sets bound alias", function() {
    expect(I18n.l).toEqual(jasmine.any(Function));
    expect(I18n.l).not.toBe(I18n.localize);
  });

  it("localizes number", function(){
    expect(I18n.localize("number", 1234567)).toEqual("1,234,567.000");
  });

  it("localizes number with 'l' shortcut", function(){
    var l = I18n.l;
    expect(l("number", 1234567)).toEqual("1,234,567.000");
  });

  it("localizes currency", function(){
    expect(I18n.localize("currency", 1234567)).toEqual("$1,234,567.00");
  });

  it("localizes date strings", function(){
    I18n.locale = "pt-BR";

    expect(I18n.localize("date.formats.default", "2009-11-29")).toEqual("29/11/2009");
    expect(I18n.localize("date.formats.short", "2009-01-07")).toEqual("07 de Janeiro");
    expect(I18n.localize("date.formats.long", "2009-01-07")).toEqual("07 de Janeiro de 2009");
  });

  it("localizes strings with locale from options", function(){
    I18n.locale = "en";

    expect(I18n.localize("date.formats.default", "2009-11-29", { locale: "pt-BR" })).toEqual("29/11/2009");
    expect(I18n.localize("date.formats.short", "2009-01-07", { locale: "pt-BR" })).toEqual("07 de Janeiro");
    expect(I18n.localize("date.formats.long", "2009-01-07", { locale: "pt-BR" })).toEqual("07 de Janeiro de 2009");
    expect(I18n.localize("time.formats.default", "2009-11-29 15:07:59", { locale: "pt-BR" })).toEqual("Domingo, 29 de Novembro de 2009, 15:07 h");
    expect(I18n.localize("time.formats.short", "2009-01-07 09:12:35", { locale: "pt-BR" })).toEqual("07/01, 09:12 h");
    expect(I18n.localize("time.formats.long", "2009-11-29 15:07:59", { locale: "pt-BR" })).toEqual("Domingo, 29 de Novembro de 2009, 15:07 h");
    expect(I18n.localize("number", 1234567, { locale: "pt-BR" })).toEqual("1,234,567.000");
    expect(I18n.localize("currency", 1234567, { locale: "pt-BR" })).toEqual("R$ 1.234.567,00");
    expect(I18n.localize("percentage", 123.45, { locale: "pt-BR" })).toEqual("123,45%");
  });

  it("localizes time strings", function(){
    I18n.locale = "pt-BR";

    expect(I18n.localize("time.formats.default", "2009-11-29 15:07:59")).toEqual("Domingo, 29 de Novembro de 2009, 15:07 h");
    expect(I18n.localize("time.formats.short", "2009-01-07 09:12:35")).toEqual("07/01, 09:12 h");
    expect(I18n.localize("time.formats.long", "2009-11-29 15:07:59")).toEqual("Domingo, 29 de Novembro de 2009, 15:07 h");
  });

  it("return 'Invalid Date' or original value for invalid input", function(){
    expect(I18n.localize("time.formats.default", "")).toEqual("Invalid Date");
    expect(I18n.localize("time.formats.default", null)).toEqual(null);
    expect(I18n.localize("time.formats.default", undefined)).toEqual(undefined);
  });

  it("localizes date/time strings with placeholders", function(){
    I18n.locale = "pt-BR";

    expect(I18n.localize("date.formats.short_with_placeholders", "2009-01-07", { p1: "!", p2: "?" })).toEqual("07 de Janeiro ! ?");
    expect(I18n.localize("time.formats.short_with_placeholders", "2009-01-07 09:12:35", { p1: "!" })).toEqual("07/01, 09:12 h !");
  });

  it("localizes percentage", function(){
    I18n.locale = "pt-BR";
    expect(I18n.localize("percentage", 123.45)).toEqual("123,45%");
  });
});
