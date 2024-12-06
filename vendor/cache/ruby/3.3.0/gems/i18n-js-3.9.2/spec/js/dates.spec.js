var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Dates", function(){
  var actual, expected;

  beforeEach(function() {
    I18n.reset();
    I18n.translations = Translations();
  });

  it("parses date", function(){
    expected = new Date(2009, 0, 24, 0, 0, 0);
    actual = I18n.parseDate("2009-01-24");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 0, 15, 0);
    actual = I18n.parseDate("2009-01-24 00:15:00");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 0, 0, 15);
    actual = I18n.parseDate("2009-01-24 00:00:15");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 15, 33, 44);
    actual = I18n.parseDate("2009-01-24 15:33:44");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 0, 0, 0);
    actual = I18n.parseDate(expected.getTime());
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 0, 0, 0);
    actual = I18n.parseDate("01/24/2009");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 14, 33, 55);
    actual = I18n.parseDate(expected).toString();
    expect(actual).toEqual(expected.toString());

    expected = new Date(2009, 0, 24, 15, 33, 44);
    actual = I18n.parseDate("2009-01-24T15:33:44");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(Date.UTC(2011, 6, 20, 12, 51, 55));
    actual = I18n.parseDate("2011-07-20T12:51:55+0000");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(Date.UTC(2011, 6, 20, 12, 51, 55));
    actual = I18n.parseDate("2011-07-20T12:51:55+00:00");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(Date.UTC(2011, 6, 20, 13, 03, 39));
    actual = I18n.parseDate("Wed Jul 20 13:03:39 +0000 2011");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(Date.UTC(2009, 0, 24, 15, 33, 44));
    actual = I18n.parseDate("2009-01-24T15:33:44Z");
    expect(actual.toString()).toEqual(expected.toString());

    expected = new Date(Date.UTC(2009, 0, 24, 15, 34, 44, 200));
    actual = I18n.parseDate("2009-01-24T15:34:44.200Z");
    expect(actual.toString()).toEqual(expected.toString());
    expect(actual.getMilliseconds()).toEqual(expected.getMilliseconds())

    expected = new Date(Date.UTC(2009, 0, 24, 15, 34, 45, 200));
    actual = I18n.parseDate("2009-01-24T15:34:45.200+0000");
    expect(actual.toString()).toEqual(expected.toString());
    expect(actual.getMilliseconds()).toEqual(expected.getMilliseconds())

    expected = new Date(Date.UTC(2009, 0, 24, 15, 34, 46, 200));
    actual = I18n.parseDate("2009-01-24T15:34:46.200+00:00");
    expect(actual.toString()).toEqual(expected.toString());
    expect(actual.getMilliseconds()).toEqual(expected.getMilliseconds())
  });

  it("formats date", function(){
    I18n.locale = "pt-BR";

    // 2009-04-26 19:35:44 (Sunday)
    var date = new Date(2009, 3, 26, 19, 35, 44);

    // short week day
    expect(I18n.strftime(date, "%a")).toEqual("Dom");

    // full week day
    expect(I18n.strftime(date, "%A")).toEqual("Domingo");

    // short month
    expect(I18n.strftime(date, "%b")).toEqual("Abr");

    // full month
    expect(I18n.strftime(date, "%B")).toEqual("Abril");

    // day
    expect(I18n.strftime(date, "%d")).toEqual("26");

    // 24-hour
    expect(I18n.strftime(date, "%H")).toEqual("19");

    // 12-hour
    expect(I18n.strftime(date, "%I")).toEqual("07");

    // month
    expect(I18n.strftime(date, "%m")).toEqual("04");

    // minutes
    expect(I18n.strftime(date, "%M")).toEqual("35");

    // meridian
    expect(I18n.strftime(date, "%p")).toEqual("PM");

    // seconds
    expect(I18n.strftime(date, "%S")).toEqual("44");

    // week day
    expect(I18n.strftime(date, "%w")).toEqual("0");

    // short year
    expect(I18n.strftime(date, "%y")).toEqual("09");

    // full year
    expect(I18n.strftime(date, "%Y")).toEqual("2009");
  });

  it("formats date without padding", function(){
    I18n.locale = "pt-BR";

    // 2009-04-26 19:35:44 (Sunday)
    var date = new Date(2009, 3, 9, 7, 8, 9);

    // 24-hour without padding
    expect(I18n.strftime(date, "%-H")).toEqual("7");
    expect(I18n.strftime(date, "%k")).toEqual("7");

    // 12-hour without padding
    expect(I18n.strftime(date, "%-I")).toEqual("7");
    expect(I18n.strftime(date, "%l")).toEqual("7");

    // minutes without padding
    expect(I18n.strftime(date, "%-M")).toEqual("8");

    // seconds without padding
    expect(I18n.strftime(date, "%-S")).toEqual("9");

    // short year without padding
    expect(I18n.strftime(date, "%-y")).toEqual("9");

    // month without padding
    expect(I18n.strftime(date, "%-m")).toEqual("4");

    // day without padding
    expect(I18n.strftime(date, "%-d")).toEqual("9");
    expect(I18n.strftime(date, "%e")).toEqual("9");
  });

  it("formats date with padding", function(){
    I18n.locale = "pt-BR";

    // 2009-04-26 19:35:44 (Sunday)
    var date = new Date(2009, 3, 9, 7, 8, 9);

    // 24-hour
    expect(I18n.strftime(date, "%H")).toEqual("07");

    // 12-hour
    expect(I18n.strftime(date, "%I")).toEqual("07");

    // minutes
    expect(I18n.strftime(date, "%M")).toEqual("08");

    // seconds
    expect(I18n.strftime(date, "%S")).toEqual("09");

    // short year
    expect(I18n.strftime(date, "%y")).toEqual("09");

    // month
    expect(I18n.strftime(date, "%m")).toEqual("04");

    // day
    expect(I18n.strftime(date, "%d")).toEqual("09");
  });

  it("formats date with negative time zone", function(){
    I18n.locale = "pt-BR";
    var date = new Date(2009, 3, 26, 19, 35, 44);

    spyOn(date, "getTimezoneOffset").andReturn(345);

    expect(I18n.strftime(date, "%z")).toMatch(/^(\+|-)[\d]{4}$/);
    expect(I18n.strftime(date, "%Z")).toMatch(/^(\+|-)[\d]{4}$/);
    expect(I18n.strftime(date, "%z")).toEqual("-0545");
    expect(I18n.strftime(date, "%Z")).toEqual("-0545");
  });

  it("formats date with positive time zone", function(){
    I18n.locale = "pt-BR";
    var date = new Date(2009, 3, 26, 19, 35, 44);

    spyOn(date, "getTimezoneOffset").andReturn(-345);

    expect(I18n.strftime(date, "%z")).toMatch(/^(\+|-)[\d]{4}$/);
    expect(I18n.strftime(date, "%Z")).toMatch(/^(\+|-)[\d]{4}$/);
    expect(I18n.strftime(date, "%z")).toEqual("+0545");
    expect(I18n.strftime(date, "%Z")).toEqual("+0545");
  });

  it("formats date with custom meridian", function(){
    I18n.locale = "en-US";
    var date = new Date(2009, 3, 26, 19, 35, 44);
    expect(I18n.strftime(date, "%p")).toEqual("pm");
    expect(I18n.strftime(date, "%P")).toEqual("pm");
  });

  it("formats date with meridian boundaries", function(){
    I18n.locale = "en-US";
    var date = new Date(2009, 3, 26, 0, 35, 44);
    expect(I18n.strftime(date, "%p")).toEqual("am");
    expect(I18n.strftime(date, "%P")).toEqual("am");

    date = new Date(2009, 3, 26, 12, 35, 44);
    expect(I18n.strftime(date, "%p")).toEqual("pm");
    expect(I18n.strftime(date, "%P")).toEqual("pm");
  });

  it("formats date using 12-hours format", function(){
    I18n.locale = "pt-BR";
    var date = new Date(2009, 3, 26, 19, 35, 44);
    expect(I18n.strftime(date, "%I")).toEqual("07");

    date = new Date(2009, 3, 26, 12, 35, 44);
    expect(I18n.strftime(date, "%I")).toEqual("12");

    date = new Date(2009, 3, 26, 0, 35, 44);
    expect(I18n.strftime(date, "%I")).toEqual("12");
  });

  it("defaults to English", function() {
    I18n.locale = "wk";

    var date = new Date(2009, 3, 26, 19, 35, 44);
    expect(I18n.strftime(date, "%a")).toEqual("Sun");
  });

  it("applies locale fallback", function(){
    I18n.defaultLocale = "en-US";
    I18n.locale = "de";

    var date = new Date(2009, 3, 26, 19, 35, 44);
    expect(I18n.strftime(date, "%A")).toEqual("Sonntag");

    date = new Date(2009, 3, 26, 19, 35, 44);
    expect(I18n.strftime(date, "%a")).toEqual("Sun");
  });

  it("uses time as the meridian scope", function(){
    I18n.locale = "de";

    var date = new Date(2009, 3, 26, 19, 35, 44);
    expect(I18n.strftime(date, "%p")).toEqual("de:PM");
    expect(I18n.strftime(date, "%P")).toEqual("de:pm");

    date = new Date(2009, 3, 26, 7, 35, 44);
    expect(I18n.strftime(date, "%p")).toEqual("de:AM");
    expect(I18n.strftime(date, "%P")).toEqual("de:am");
  });

  it("fails to format invalid date", function(){
    var date = new Date('foo');
    expect(function() {
      I18n.strftime(date, "%a");
    }).toThrow('I18n.strftime() requires a valid date object, but received an invalid date.');
  });
});
