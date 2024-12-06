(function(){
  var BOOLEAN_PROPERTIES = [
    "allowfullscreen",
    "allowpaymentrequest",
    "allowusermedia",
    "async",
    "autofocus",
    "autoplay",
    "checked",
    "compact",
    "complete",
    "controls",
    "declare",
    "default",
    "defaultchecked",
    "defaultselected",
    "defer",
    "disabled",
    "ended",
    "formnovalidate",
    "hidden",
    "indeterminate",
    "iscontenteditable",
    "ismap",
    "itemscope",
    "loop",
    "multiple",
    "muted",
    "nohref",
    "nomodule",
    "noresize",
    "noshade",
    "novalidate",
    "nowrap",
    "open",
    "paused",
    "playsinline",
    "pubdate",
    "readonly",
    "required",
    "reversed",
    "scoped",
    "seamless",
    "seeking",
    "selected",
    "truespeed",
    "typemustmatch",
    "willvalidate"
  ];

  var PROPERTY_ALIASES = {
    "class": "className",
    "readonly": "readOnly"
  };

  function isSelectable(element){
    var tagName = element.tagName.toUpperCase();

    if (tagName == "OPTION"){
      return true;
    }

    if (tagName == "INPUT") {
      var type = element.type.toLowerCase();
      return type == "checkbox" || type == "radio";
    }

    return false;
  }

  function isSelected(element){
    var propertyName = "selected";
    var type = element.type && element.type.toLowerCase();
    if ("checkbox" == type || "radio" == type) {
      propertyName = "checked";
    }

    return !!element[propertyName];
  }

  function getAttributeValue(element, name){
    var attr = element.getAttributeNode(name);
    return (attr && attr.specified) ? attr.value : null;
  }

  return function get(element, attribute){
    var value = null;
    var name = attribute.toLowerCase();

    if ("style" == name) {
      value = element.style;

      if (value && (typeof value != "string")) {
        value = value.cssText;
      }

      return value;
    }

    if (("selected" == name || "checked" == name) &&
        isSelectable(element)) {
      return isSelected(element) ? "true" : null;
    }

    tagName = element.tagName.toUpperCase();

    // The property is consistent. Return that in preference to the attribute for links and images.
    if (((tagName == "IMG") && name == "src") ||
        ((tagName == "A") && name == "href")) {
      value = getAttributeValue(element, name);
      if (value) {
        // We want the full URL if present
        value = element[name];
      }
      return value;
    }

    if ("spellcheck" == name) {
      value = getAttributeValue(element, name);
      if (!(value === null)) {
        if (value.toLowerCase() == "false") {
          return "false";
        } else if (value.toLowerCase() == "true") {
          return "true";
        }
      }
      // coerce the property value to a string
      return element[name] + "";
    }
    var propName = PROPERTY_ALIASES[attribute] || attribute;
    if (BOOLEAN_PROPERTIES.some(function(prop){ prop == name })) {
      value = getAttributeValue(element, name);
      value = !(value === null) || element[propName];
      return value ? "true" : null;
    }
    var property;
    try {
      property = element[propName]
    } catch (e) {
      // Leaves property undefined or null
    }
    // 1- Call getAttribute if getProperty fails,
    // i.e. property is null or undefined.
    // This happens for event handlers in Firefox.
    // For example, calling getProperty for 'onclick' would
    // fail while getAttribute for 'onclick' will succeed and
    // return the JS code of the handler.
    //
    // 2- When property is an object we fall back to the
    // actual attribute instead.
    // See issue http://code.google.com/p/selenium/issues/detail?id=966
    if ((property == null) || (typeof property == "object") || (typeof property == "function")) {
      value = getAttributeValue(element, attribute);
    } else {
      value = property;
    };

    // The empty string is a valid return value.
    return value != null ? value.toString() : null;
  };
})()