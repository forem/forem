var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Currency", function(){
  var actual, expected;

  beforeEach(function() {
    I18n.reset();
    I18n.translations = Translations();
  });

  it("formats currency with default settings", function(){
    expect(I18n.toCurrency(100.99)).toEqual("$100.99");
    expect(I18n.toCurrency(1000.99)).toEqual("$1,000.99");
    expect(I18n.toCurrency(-1000)).toEqual("-$1,000.00");
  });

  it("formats currency with custom settings", function(){
    I18n.translations.en.number = {
      currency: {
        format: {
          format: "%n %u",
          unit: "USD",
          delimiter: ".",
          separator: ",",
          precision: 2
        }
      }
    };

    expect(I18n.toCurrency(12)).toEqual("12,00 USD");
    expect(I18n.toCurrency(123)).toEqual("123,00 USD");
    expect(I18n.toCurrency(1234.56)).toEqual("1.234,56 USD");
  });

  it("formats currency with custom settings and partial overriding", function(){
    I18n.translations.en.number = {
      currency: {
        format: {
          format: "%n %u",
          unit: "USD",
          delimiter: ".",
          separator: ",",
          precision: 2
        }
      }
    };

    expect(I18n.toCurrency(12, {precision: 0})).toEqual("12 USD");
    expect(I18n.toCurrency(123, {unit: "bucks"})).toEqual("123,00 bucks");
  });

  it("formats currency with some custom options that should be merged with default options", function(){
    expect(I18n.toCurrency(1234, {precision: 0})).toEqual("$1,234");
    expect(I18n.toCurrency(1234, {unit: "º"})).toEqual("º1,234.00");
    expect(I18n.toCurrency(1234, {separator: "-"})).toEqual("$1,234-00");
    expect(I18n.toCurrency(1234, {delimiter: "-"})).toEqual("$1-234.00");
    expect(I18n.toCurrency(1234, {format: "%u %n"})).toEqual("$ 1,234.00");
    expect(I18n.toCurrency(-123, {sign_first: false})).toEqual("$-123.00");
  });
});
