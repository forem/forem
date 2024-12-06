class InvalidSelector extends Error {}
class TimedOutPromise extends Error {}
class MouseEventFailed extends Error {}

const EVENTS = {
  FOCUS: ["blur", "focus", "focusin", "focusout"],
  MOUSE: ["click", "dblclick", "mousedown", "mouseenter", "mouseleave",
          "mousemove", "mouseover", "mouseout", "mouseup", "contextmenu"],
  FORM: ["submit"]
}

class Cuprite {
  constructor() {
    this._json = JSON; // In case someone overrides it like mootools
  }

  find(method, selector, within = document) {
    try {
      let results = [];

      if (method == "xpath") {
        let xpath = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (let i = 0; i < xpath.snapshotLength; i++) {
          results.push(xpath.snapshotItem(i));
        }
      } else {
        results = Array.from(within.querySelectorAll(selector));
      }

      return results;
    } catch (error) {
      // DOMException.INVALID_EXPRESSION_ERR is undefined, using pure code
      if (error.code == DOMException.SYNTAX_ERR || error.code == 51) {
        throw new InvalidSelector;
      } else {
        throw error;
      }
    }
  }

  parents(node) {
    let nodes = [];
    let parent = node.parentNode;
    while (parent != document && parent !== null) {
      nodes.push(parent);
      parent = parent.parentNode;
    }
    return nodes;
  }

  visibleText(node) {
    if (this.isVisible(node)) {
      if (node.nodeName == "TEXTAREA") {
        return node.textContent;
      } else {
        if (node instanceof SVGElement) {
          return node.textContent;
        } else {
          return node.innerText;
        }
      }
    }
  }

  isVisible(node) {
    let mapName, style;
    // if node is area, check visibility of relevant image
    if (node.tagName === "AREA") {
      mapName = document.evaluate("./ancestor::map/@name", node, null, XPathResult.STRING_TYPE, null).stringValue;
      node = document.querySelector(`img[usemap="#${mapName}"]`);
      if (node == null) {
        return false;
      }
    }

    while (node) {
      style = window.getComputedStyle(node);
      if (style.display === "none" || style.visibility === "hidden" || parseFloat(style.opacity) === 0) {
        return false;
      }
      node = node.parentElement;
    }

    return true;
  }


  isDisabled(node) {
    let xpath = "parent::optgroup[@disabled] | \
                 ancestor::select[@disabled] | \
                 parent::fieldset[@disabled] | \
                 ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]";

    return node.disabled || document.evaluate(xpath, node, null, XPathResult.BOOLEAN_TYPE, null).booleanValue;
  }

  path(node) {
    let nodes = [node];
    let parent = node.parentNode;
    while (parent !== document && parent !== null) {
      nodes.unshift(parent);
      parent = parent.parentNode;
    }

    let selectors = nodes.map(node => {
      let prevSiblings = [];
      let xpath = document.evaluate(`./preceding-sibling::${node.tagName}`, node, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

      for (let i = 0; i < xpath.snapshotLength; i++) {
        prevSiblings.push(xpath.snapshotItem(i));
      }

      return `${node.tagName}[${(prevSiblings.length + 1)}]`;
    });

    return `//${selectors.join("/")}`;
  }

  set(node, value) {
    if (node.readOnly) return;

    if (node.maxLength >= 0) {
      value = value.substr(0, node.maxLength);
    }

    let valueBefore = node.value;

    this.trigger(node, "focus");
    this.setValue(node, "");

    if (node.type == "number" || node.type == "date" || node.type == "range") {
      this.setValue(node, value);
      this.input(node);
    } else if (node.type == "time") {
      this.setValue(node, new Date(value).toTimeString().split(" ")[0]);
      this.input(node);
    } else if (node.type == "datetime-local") {
      value = new Date(value);
      let year = value.getFullYear();
      let month = ("0" + (value.getMonth() + 1)).slice(-2);
      let date = ("0" + value.getDate()).slice(-2);
      let hour = ("0" + value.getHours()).slice(-2);
      let min = ("0" + value.getMinutes()).slice(-2);
      let sec = ("0" + value.getSeconds()).slice(-2);
      this.setValue(node, `${year}-${month}-${date}T${hour}:${min}:${sec}`);
      this.input(node);
    } else {
      for (let i = 0; i < value.length; i++) {
        let char = value[i];
        let keyCode = this.characterToKeyCode(char);
        // call the following functions in order, if one returns false (preventDefault),
        // stop the call chain
        [
          () => this.keyupdowned(node, "keydown", char, keyCode),
          () => this.keypressed(node, false, false, false, false, char.charCodeAt(0), char.charCodeAt(0)),
          () => {
            this.setValue(node, node.value + char)
            this.input(node)
          }
        ].some(fn => fn())

        this.keyupdowned(node, "keyup", char, keyCode);
      }
    }

    if (valueBefore !== node.value) {
      this.changed(node);
    }
    this.trigger(node, "blur");
  }

  setValue(node, value) {
    let nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
    let nativeTextareaValueSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, "value").set;

    if (node.tagName.toLowerCase() === 'input') {
      return nativeInputValueSetter.call(node, value);
    }
    return nativeTextareaValueSetter.call(node, value);
  }

  input(node) {
    let event = new InputEvent("input", { inputType: "insertText", bubbles: true, cancelable: false });
    node.dispatchEvent(event);
  }

  /**
   * @return {boolean} false when an event handler called preventDefault()
   */
  keyupdowned(node, eventName, char, keyCode) {
    let event = new KeyboardEvent(
      eventName, {
        bubbles: true,
        cancelable: true,
        key: char,
        keyCode: keyCode
      }
    );
    return !node.dispatchEvent(event);
  }

  /**
   * @return {boolean} false when an event handler called preventDefault()
   */
  keypressed(node, altKey, ctrlKey, shiftKey, metaKey, keyCode, charCode) {
    let event = new KeyboardEvent(
      "keypress", {
        bubbles: true,
        cancelable: true,
        altKey: altKey,
        ctrlKey: ctrlKey,
        shiftKey: shiftKey,
        metaKey: metaKey,
        keyCode: keyCode,
        charCode: charCode
      }
    );
    return !node.dispatchEvent(event);
  }

  characterToKeyCode(char) {
    const specialKeys = {
      96: 192,  // `
      45: 189,  // -
      61: 187,  // =
      91: 219,  // [
      93: 221,  // ]
      92: 220,  // \
      59: 186,  // ;
      39: 222,  // '
      44: 188,  // ,
      46: 190,  // .
      47: 191,  // /
      127: 46,  // delete
      126: 192, // ~
      33: 49,   // !
      64: 50,   // @
      35: 51,   // #
      36: 52,   // $
      37: 53,   // %
      94: 54,   // ^
      38: 55,   // &
      42: 56,   // *
      40: 57,   // (
      41: 48,   // )
      95: 189,  // _
      43: 187,  // +
      123: 219, // {
      125: 221, // }
      124: 220, // |
      58: 186,  // :
      34: 222,  // "
      60: 188,  // <
      62: 190,  // >
      63: 191,  // ?
    }

    let code = char.toUpperCase().charCodeAt(0);
    return specialKeys[code] || code;
  }

  scrollIntoViewport(node) {
    let areaImage = this._getAreaImage(node);

    if (areaImage) {
      return this.scrollIntoViewport(areaImage);
    } else {
      node.scrollIntoViewIfNeeded();

      if (!this._isInViewport(node)) {
        node.scrollIntoView({block: "center", inline: "center", behavior: "instant"});
        return this._isInViewport(node);
      }

      return true;
    }
  }

  mouseEventTest(node, name, x, y) {
    let frameOffset = this._frameOffset();
    x -= frameOffset.left;
    y -= frameOffset.top;

    let element = document.elementFromPoint(x, y);

    let el = element;
    while (el) {
      if (el == node) {
        return true;
      } else {
        el = el.parentNode;
      }
    }

    let selector = element && this._getSelector(element) || "none";
    throw new MouseEventFailed([name, selector, x, y].join(", "));
  }

  _getAreaImage(node) {
    if ("area" == node.tagName.toLowerCase()) {
      let map = node.parentNode;
      if (map.tagName.toLowerCase() != "map") {
        throw new Error("the area is not within a map");
      }

      let mapName = map.getAttribute("name");
      if (typeof mapName === "undefined" || mapName === null) {
        throw new Error("area's parent map must have a name");
      }

      mapName = `#${mapName.toLowerCase()}`;
      let imageNode = this.find("css", `img[usemap='${mapName}']`)[0];
      if (typeof imageNode === "undefined" || imageNode === null) {
        throw new Error("no image matches the map");
      }

      return imageNode;
    }
  }

  _frameOffset() {
    let win = window;
    let offset = { top: 0, left: 0 };

    while (win.frameElement) {
      let rect = win.frameElement.getClientRects()[0];
      let style = win.getComputedStyle(win.frameElement);
      win = win.parent;

      offset.top += rect.top + parseInt(style.getPropertyValue("padding-top"), 10)
      offset.left += rect.left + parseInt(style.getPropertyValue("padding-left"), 10)
    }

    return offset;
  }

  _getSelector(el) {
    let selector = (el.tagName != 'HTML') ? this._getSelector(el.parentNode) + " " : "";
    selector += el.tagName.toLowerCase();
    if (el.id) { selector += `#${el.id}` };
    el.classList.forEach(c => selector += `.${c}`);
    return selector;
  }

  _isInViewport(node) {
    let rect = node.getBoundingClientRect();
    return rect.top >= 0 &&
           rect.left >= 0 &&
           rect.bottom <= window.innerHeight &&
           rect.right <= window.innerWidth;
  }

  select(node, value) {
    if (this.isDisabled(node)) {
      return false;
    } else if (value == false && !node.parentNode.multiple) {
      return false;
    } else {
      this.trigger(node.parentNode, "focus");

      node.selected = value;
      this.changed(node);

      this.trigger(node.parentNode, "blur");
      return true;
    }
  }

  changed(node) {
    let element;
    let event = document.createEvent("HTMLEvents");
    event.initEvent("change", true, false);

    // In the case of an OPTION tag, the change event should come
    // from the parent SELECT
    if (node.nodeName == "OPTION") {
      element = node.parentNode
      if (element.nodeName == "OPTGROUP") {
        element = element.parentNode
      }
      element
    } else {
      element = node
    }

    element.dispatchEvent(event)
  }

  trigger(node, name, options = {}) {
    let event;

    if (EVENTS.MOUSE.indexOf(name) != -1) {
      event = document.createEvent("MouseEvent");
      event.initMouseEvent(
        name, true, true, window, 0,
        options["screenX"] || 0, options["screenY"] || 0,
        options["clientX"] || 0, options["clientY"] || 0,
        options["ctrlKey"] || false,
        options["altKey"] || false,
        options["shiftKey"] || false,
        options["metaKey"] || false,
        options["button"] || 0, null
      )
    } else if (EVENTS.FOCUS.indexOf(name) != -1) {
      event = this.obtainEvent(name);
    } else if (EVENTS.FORM.indexOf(name) != -1) {
      event = this.obtainEvent(name);
    } else {
      throw "Unknown event";
    }

    node.dispatchEvent(event);
  }

  obtainEvent(name) {
    let event = document.createEvent("HTMLEvents");
    event.initEvent(name, true, true);
    return event;
  }

  getAttributes(node) {
    let attrs = {};
    for (let i = 0, len = node.attributes.length; i < len; i++) {
      let attr = node.attributes[i];
      attrs[attr.name] = attr.value.replace("\n", "\\n");
    }

    return this._json.stringify(attrs);
  }

  getAttribute(node, name) {
    if (name == "checked" || name == "selected") {
      return node[name];
    } else {
      return node.getAttribute(name);
    }
  }

  value(node) {
    if (node.tagName == "SELECT" && node.multiple) {
      let result = []

      for (let i = 0, len = node.children.length; i < len; i++) {
        let option = node.children[i];
        if (option.selected) {
          result.push(option.value);
        }
      }

      return result;
    } else {
      return node.value;
    }
  }

  deleteText(node) {
    let range = document.createRange();
    range.selectNodeContents(node);
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    window.getSelection().deleteFromDocument();
  }

  containsSelection(node) {
    let selectedNode = document.getSelection().focusNode;

    if (!selectedNode) {
      return false;
    }

    if (selectedNode.nodeType == 3) {
      selectedNode = selectedNode.parentNode;
    }

    return node.contains(selectedNode);
  }

  // This command is purely for testing error handling
  browserError() {
    throw new Error("zomg");
  }
}

window._cuprite = new Cuprite;
