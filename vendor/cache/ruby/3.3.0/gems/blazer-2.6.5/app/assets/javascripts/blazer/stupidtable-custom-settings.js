function removeCommas(string) {
  return string.replace(/,/g, "")
}

// Remove commas for integers and floats to fix issues with sorting in the stupidtable plugin
var stupidtableCustomSettings = {
  "int": function(a, b) {
    return parseInt(removeCommas(a), 10) - parseInt(removeCommas(b), 10);
  },
  "float": function(a, b) {
    return parseFloat(removeCommas(a)) - parseFloat(removeCommas(b));
  }
}
