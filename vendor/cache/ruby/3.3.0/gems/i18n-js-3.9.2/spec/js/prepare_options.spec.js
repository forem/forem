var I18n = require("../../app/assets/javascripts/i18n");

describe("Prepare options", function(){
  beforeEach(function(){
    I18n.reset();
  });

  it("merges two objects", function(){
    var options = I18n.prepareOptions(
      {name: "Mary Doe"},
      {name: "John Doe", role: "user"}
    );

    expect(options.name).toEqual("Mary Doe");
    expect(options.role).toEqual("user");
  });

  it("merges multiple objects", function(){
    var options = I18n.prepareOptions(
      {name: "Mary Doe"},
      {name: "John Doe", role: "user"},
      {age: 33},
      {email: "mary@doe.com", url: "http://marydoe.com"},
      {role: "admin", email: "john@doe.com"}
    );

    expect(options.name).toEqual("Mary Doe");
    expect(options.role).toEqual("user");
    expect(options.age).toEqual(33);
    expect(options.email).toEqual("mary@doe.com");
    expect(options.url).toEqual("http://marydoe.com");
  });

  it("returns an empty object when values are null", function(){
    expect(I18n.prepareOptions(null, null)).toEqual({});
  });

  it("returns an empty object when values are undefined", function(){
    expect(I18n.prepareOptions(undefined, undefined)).toEqual({});
  });
});
