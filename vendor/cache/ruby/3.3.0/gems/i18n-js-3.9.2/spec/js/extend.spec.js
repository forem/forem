var I18n = require("../../app/assets/javascripts/i18n")
  , Translations = require("./translations")
;

describe("Extend", function () {
  it("should return an object", function () {
    expect(typeof I18n.extend()).toBe('object');
  });

  it("should merge 2 objects into 1", function () {
    var obj1 = {
      test1: "abc"
    }
    , obj2 = {
      test2: "xyz"
    }
    , expected = {
      test1: "abc"
      , test2: "xyz"
    };

    expect(I18n.extend(obj1,obj2)).toEqual(expected);
  });
  it("should overwrite a property from obj1 with the same property of obj2", function () {
    var obj1 = {
      test1: "abc"
      , test3: "def"
    }
    , obj2 = {
      test2: "xyz"
      , test3: "uvw"
    }
    , expected = {
      test1: "abc"
      , test2: "xyz"
      , test3: "uvw"
    };

    expect(I18n.extend(obj1,obj2)).toEqual(expected);
  });

  it("should merge deeply from obj1 with the same key of obj2", function() {
    var obj1 = {
      test1: {
        test2: "abc"
      }
    }
    , obj2 = {
      test1: {
        test3: "xyz"
      }
    }
    , expected = {
      test1: {
        test2: "abc"
        , test3: "xyz"
      }
    }

    expect(I18n.extend(obj1, obj2)).toEqual(expected);
  });

  it("should correctly merge string, numberic, boolean, and null values", function() {
    var obj1 = {
      test1: {
        test2: false
      }
    }
    , obj2 = {
      test1: {
        test3: 23,
        test4: 'abc',
        test5: null
      }
    }
    , expected = {
      test1: {
        test2: false
        , test3: 23
        , test4: 'abc'
        , test5: null
      }
    }

    expect(I18n.extend(obj1, obj2)).toEqual(expected);
  });

  it("should merge array values", function() {
    var obj1 = {
      array1: [1, 2]
    },
    obj2 = {
      array2: [1, 2],
      obj3: {
        array3: [1, 2],
        array4: [{obj4: 1}, 2]
      }
    },
    expected = {
      array1: [1, 2],
      array2: [1, 2],
      obj3: {
        array3: [1, 2],
        array4: [{obj4: 1}, 2]
      }
    }

    expect(JSON.stringify(I18n.extend(obj1, obj2))).toEqual(JSON.stringify(expected));
  });
});
