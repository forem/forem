var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Numbers", function(){
  var actual, expected;

  beforeEach(function() {
    I18n.reset();
    I18n.translations = Translations();
  });

  it("formats number with default settings", function(){
    expect(I18n.toNumber(1)).toEqual("1.000");
    expect(I18n.toNumber(12)).toEqual("12.000");
    expect(I18n.toNumber(123)).toEqual("123.000");
    expect(I18n.toNumber(1234)).toEqual("1,234.000");
    expect(I18n.toNumber(12345)).toEqual("12,345.000");
    expect(I18n.toNumber(123456)).toEqual("123,456.000");
    expect(I18n.toNumber(1234567)).toEqual("1,234,567.000");
    expect(I18n.toNumber(12345678)).toEqual("12,345,678.000");
    expect(I18n.toNumber(123456789)).toEqual("123,456,789.000");
  });

  it("formats negative numbers with default settings", function(){
    expect(I18n.toNumber(-1)).toEqual("-1.000");
    expect(I18n.toNumber(-12)).toEqual("-12.000");
    expect(I18n.toNumber(-123)).toEqual("-123.000");
    expect(I18n.toNumber(-1234)).toEqual("-1,234.000");
    expect(I18n.toNumber(-12345)).toEqual("-12,345.000");
    expect(I18n.toNumber(-123456)).toEqual("-123,456.000");
    expect(I18n.toNumber(-1234567)).toEqual("-1,234,567.000");
    expect(I18n.toNumber(-12345678)).toEqual("-12,345,678.000");
    expect(I18n.toNumber(-123456789)).toEqual("-123,456,789.000");
  });

  it("formats number with partial translation and default options", function(){
    I18n.translations.en.number = {
      format: {
        precision: 2
      }
    };

    expect(I18n.toNumber(1234)).toEqual("1,234.00");
  });

  it("formats number with full translation and default options", function(){
    I18n.translations.en.number = {
      format: {
        delimiter: ".",
        separator: ",",
        precision: 2
      }
    };

    expect(I18n.toNumber(1234)).toEqual("1.234,00");
  });

  it("formats numbers with some custom options that should be merged with default options", function(){
    expect(I18n.toNumber(1234.56, {precision: 0})).toEqual("1,235");
    expect(I18n.toNumber(1234, {separator: '-'})).toEqual("1,234-000");
    expect(I18n.toNumber(1234, {delimiter: '_'})).toEqual("1_234.000");
  });

  it("formats number considering options", function(){
    options = {
      precision: 2,
      separator: ",",
      delimiter: "."
    };

    expect(I18n.toNumber(1, options)).toEqual("1,00");
    expect(I18n.toNumber(12, options)).toEqual("12,00");
    expect(I18n.toNumber(123, options)).toEqual("123,00");
    expect(I18n.toNumber(1234, options)).toEqual("1.234,00");
    expect(I18n.toNumber(123456, options)).toEqual("123.456,00");
    expect(I18n.toNumber(1234567, options)).toEqual("1.234.567,00");
    expect(I18n.toNumber(12345678, options)).toEqual("12.345.678,00");
  });

  it("formats numbers with different precisions", function(){
    options = {separator: ".", delimiter: ","};

    options["precision"] = 2;
    expect(I18n.toNumber(1.98, options)).toEqual("1.98");

    options["precision"] = 3;
    expect(I18n.toNumber(1.98, options)).toEqual("1.980");

    options["precision"] = 2;
    expect(I18n.toNumber(1.987, options)).toEqual("1.99");

    options["precision"] = 1;
    expect(I18n.toNumber(1.98, options)).toEqual("2.0");

    options["precision"] = 0;
    expect(I18n.toNumber(1.98, options)).toEqual("2");
  });

  it("rounds numbers correctly when precision is given", function(){
    options = {separator: ".", delimiter: ","};

    options["precision"] = 2;
    expect(I18n.toNumber(0.104, options)).toEqual("0.10");

    options["precision"] = 2;
    expect(I18n.toNumber(0.105, options)).toEqual("0.11");

    options["precision"] = 2;
    expect(I18n.toNumber(1.005, options)).toEqual("1.01");

    options["precision"] = 3;
    expect(I18n.toNumber(35.855, options)).toEqual("35.855");

    options["precision"] = 2;
    expect(I18n.toNumber(35.855, options)).toEqual("35.86");

    options["precision"] = 1;
    expect(I18n.toNumber(35.855, options)).toEqual("35.9");

    options["precision"] = 0;
    expect(I18n.toNumber(35.855, options)).toEqual("36");

    options["precision"] = 0;
    expect(I18n.toNumber(0.000000000000001, options)).toEqual("0");
  });

  it("returns number as human size", function(){
    var kb = 1024;

    expect(I18n.toHumanSize(1)).toEqual("1Byte");
    expect(I18n.toHumanSize(100)).toEqual("100Bytes");

    expect(I18n.toHumanSize(kb)).toEqual("1KB");
    expect(I18n.toHumanSize(kb * 1.5)).toEqual("1.5KB");

    expect(I18n.toHumanSize(kb * kb)).toEqual("1MB");
    expect(I18n.toHumanSize(kb * kb * 1.5)).toEqual("1.5MB");

    expect(I18n.toHumanSize(kb * kb * kb)).toEqual("1GB");
    expect(I18n.toHumanSize(kb * kb * kb * 1.5)).toEqual("1.5GB");

    expect(I18n.toHumanSize(kb * kb * kb * kb)).toEqual("1TB");
    expect(I18n.toHumanSize(kb * kb * kb * kb * 1.5)).toEqual("1.5TB");

    expect(I18n.toHumanSize(kb * kb * kb * kb * kb)).toEqual("1024TB");
  });

  it("returns number as human size using custom options", function(){
    expect(I18n.toHumanSize(1024 * 1.6, {precision: 0})).toEqual("2KB");
  });

  it("returns number as human size using custom scope", function(){
    expect(I18n.toHumanSize(1024 * 1024, {scope: "extended"})).toEqual("1Megabyte");
  });

  it("formats numbers with strip insignificant zero", function() {
    options = {separator: ".", delimiter: ",", strip_insignificant_zeros: true};

    options["precision"] = 2;
    expect(I18n.toNumber(1.0, options)).toEqual("1");

    options["precision"] = 3;
    expect(I18n.toNumber(1.98, options)).toEqual("1.98");

    options["precision"] = 4;
    expect(I18n.toNumber(1.987, options)).toEqual("1.987");
  });

  it("keeps significant zeros [issue#103]", function() {
    actual = I18n.toNumber(30, {strip_insignificant_zeros: true, precision: 0});
    expect(actual).toEqual("30");
  });
});
