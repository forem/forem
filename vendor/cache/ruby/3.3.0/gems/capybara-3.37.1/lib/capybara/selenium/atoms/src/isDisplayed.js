(function(){
  var OverflowState = {
    NONE: "none",
    HIDDEN: "hidden",
    SCROLL: "scroll"
  };

  function isShown_(elem, ignoreOpacity, parentsDisplayedFn) {
    // By convention, BODY element is always shown: BODY represents the document
    // and even if there's nothing rendered in there, user can always see there's
    // the document.
    var elemTagName = elem.tagName.toUpperCase();
    if (elemTagName == "BODY") {
      return true;
    }

    // Option or optgroup is shown if enclosing select is shown (ignoring the
    // select's opacity).
    if ((elemTagName == "OPTION") ||
        (elemTagName == "OPTGROUP")) {
      var select = getAncestor(elem, function(e) {
        return e.tagName.toUpperCase() == "SELECT";
      });
      return !!select && isShown_(select, true, parentsDisplayedFn);
    }

    // Image map elements are shown if image that uses it is shown, and
    // the area of the element is positive.
    var imageMap = maybeFindImageMap_(elem);
    if (imageMap) {
      return !!imageMap.image &&
             imageMap.rect.width > 0 && imageMap.rect.height > 0 &&
             isShown_(imageMap.image, ignoreOpacity, parentsDisplayedFn);
    }

    // Any hidden input is not shown.
    if ((elemTagName == "INPUT") && (elem.type.toLowerCase() == "hidden")) {
      return false;
    }

    // Any NOSCRIPT element is not shown.
    if (elemTagName == "NOSCRIPT") {
      return false;
    }

    // Any element with hidden/collapsed visibility is not shown.
    var visibility = window.getComputedStyle(elem)["visibility"];
    if (visibility == "collapse" || visibility == "hidden") {
      return false;
    }

    if (!parentsDisplayedFn(elem)) {
      return false;
    }

    // Any transparent element is not shown.
    if (!ignoreOpacity && getOpacity(elem) == 0) {
      return false;
    }

    // Any element without positive size dimensions is not shown.
    function positiveSize(e) {
      var rect = getClientRect(e);
      if (rect.height > 0 && rect.width > 0) {
        return true;
      }

      // A vertical or horizontal SVG Path element will report zero width or
      // height but is "shown" if it has a positive stroke-width.
      if ((e.tagName.toUpperCase() == "PATH") && (rect.height > 0 || rect.width > 0)) {
        var strokeWidth = window.getComputedStyle(e)["stroke-width"];
        return !!strokeWidth && (parseInt(strokeWidth, 10) > 0);
      }

      // Zero-sized elements should still be considered to have positive size
      // if they have a child element or text node with positive size, unless
      // the element has an 'overflow' style of "hidden".
      return window.getComputedStyle(e)["overflow"] != "hidden" &&
        Array.prototype.slice.call(e.childNodes).some(function(n) {
          return (n.nodeType == Node.TEXT_NODE) ||
                 ((n.nodeType == Node.ELEMENT_NODE) && positiveSize(n));
          });
    }

    if (!positiveSize(elem)) {
      return false;
    }

    // Elements that are hidden by overflow are not shown.
    function hiddenByOverflow(e) {
      return getOverflowState(e) == OverflowState.HIDDEN &&
          Array.prototype.slice.call(e.childNodes).every(function(n) {
            return (n.nodeType != Node.ELEMENT_NODE) || hiddenByOverflow(n) ||
                   !positiveSize(n);
          });
    }
    return !hiddenByOverflow(elem);
  }

  function getClientRegion(elem) {
    var region = getClientRect(elem);
    return { left: region.left,
             right: region.left + region.width,
             top: region.top,
             bottom: region.top + region.height };
  }

  function getParentElement(node) {
    return node.parentElement
  }

  function getOverflowState(elem) {
    var region = getClientRegion(elem);
    var ownerDoc = elem.ownerDocument;
    var htmlElem = ownerDoc.documentElement;
    var bodyElem = ownerDoc.body;
    var htmlOverflowStyle = window.getComputedStyle(htmlElem)["overflow"];
    var treatAsFixedPosition;

    // Return the closest ancestor that the given element may overflow.
    function getOverflowParent(e) {
      function canBeOverflowed(container) {
        // The HTML element can always be overflowed.
        if (container == htmlElem) {
          return true;
        }
        var containerStyle = window.getComputedStyle(container);
        // An element cannot overflow an element with an inline or contents display style.
        var containerDisplay = containerStyle["display"];
        if ((containerDisplay.indexOf("inline") == 0) ||
            (containerDisplay == "contents")) {
          return false;
        }
        // An absolute-positioned element cannot overflow a static-positioned one.
        if ((position == "absolute") && (containerStyle["position"] == "static")) {
          return false;
        }
        return true;
      }

      var position = window.getComputedStyle(e)["position"];
      if (position == "fixed") {
        treatAsFixedPosition = true;
        // Fixed-position element may only overflow the viewport.
        return e == htmlElem ? null : htmlElem;
      } else {
        var parent = getParentElement(e);
        while (parent && !canBeOverflowed(parent)) {
          parent = getParentElement(parent);
        }
        return parent;
      }
    };

    // Return the x and y overflow styles for the given element.
    function getOverflowStyles(e) {
      // When the <html> element has an overflow style of 'visible', it assumes
      // the overflow style of the body, and the body is really overflow:visible.
      var overflowElem = e;
      if (htmlOverflowStyle == "visible") {
        // NOTE: bodyElem will be null/undefined in SVG documents.
        if (e == htmlElem && bodyElem) {
          overflowElem = bodyElem;
        } else if (e == bodyElem) {
          return {x: "visible", y: "visible"};
        }
      }
      var overflowElemStyle = window.getComputedStyle(overflowElem);
      var overflow = {
        x: overflowElemStyle["overflow-x"],
        y: overflowElemStyle["overflow-y"]
      };
      // The <html> element cannot have a genuine 'visible' overflow style,
      // because the viewport can't expand; 'visible' is really 'auto'.
      if (e == htmlElem) {
        overflow.x = overflow.x == "visible" ? "auto" : overflow.x;
        overflow.y = overflow.y == "visible" ? "auto" : overflow.y;
      }
      return overflow;
    };

    // Returns the scroll offset of the given element.
    function getScroll(e) {
      if (e == htmlElem) {
        return { x: window.scrollX, y: window.scrollY }
      }
      return { x: e.scrollLeft, y: e.scrollTop }
    }

    // Check if the element overflows any ancestor element.
    for (var container = getOverflowParent(elem);
         !!container;
         container = getOverflowParent(container)) {
      var containerOverflow = getOverflowStyles(container);

      // If the container has overflow:visible, the element cannot overflow it.
      if (containerOverflow.x == "visible" && containerOverflow.y == "visible") {
        continue;
      }

      var containerRect = getClientRect(container);

      // Zero-sized containers without overflow:visible hide all descendants.
      if (containerRect.width == 0 || containerRect.height == 0) {
        return OverflowState.HIDDEN;
      }

      // Check "underflow": if an element is to the left or above the container
      var underflowsX = region.right < containerRect.left;
      var underflowsY = region.bottom < containerRect.top;
      if ((underflowsX && containerOverflow.x == "hidden") ||
          (underflowsY && containerOverflow.y == "hidden")) {
        return OverflowState.HIDDEN;
      } else if ((underflowsX && containerOverflow.x != "visible") ||
                 (underflowsY && containerOverflow.y != "visible")) {
        // When the element is positioned to the left or above a container, we
        // have to distinguish between the element being completely outside the
        // container and merely scrolled out of view within the container.
        var containerScroll = getScroll(container);
        var unscrollableX = region.right < containerRect.left - containerScroll.x;
        var unscrollableY = region.bottom < containerRect.top - containerScroll.y;
        if ((unscrollableX && containerOverflow.x != "visible") ||
            (unscrollableY && containerOverflow.x != "visible")) {
          return OverflowState.HIDDEN;
        }
        var containerState = getOverflowState(container);
        return containerState == OverflowState.HIDDEN ?
            OverflowState.HIDDEN : OverflowState.SCROLL;
      }

      // Check "overflow": if an element is to the right or below a container
      var overflowsX = region.left >= containerRect.left + containerRect.width;
      var overflowsY = region.top >= containerRect.top + containerRect.height;
      if ((overflowsX && containerOverflow.x == "hidden") ||
          (overflowsY && containerOverflow.y == "hidden")) {
        return OverflowState.HIDDEN;
      } else if ((overflowsX && containerOverflow.x != "visible") ||
                 (overflowsY && containerOverflow.y != "visible")) {
        // If the element has fixed position and falls outside the scrollable area
        // of the document, then it is hidden.
        if (treatAsFixedPosition) {
          var docScroll = getScroll(container);
          if ((region.left >= htmlElem.scrollWidth - docScroll.x) ||
              (region.right >= htmlElem.scrollHeight - docScroll.y)) {
            return OverflowState.HIDDEN;
          }
        }
        // If the element can be scrolled into view of the parent, it has a scroll
        // state; unless the parent itself is entirely hidden by overflow, in
        // which it is also hidden by overflow.
        var containerState = getOverflowState(container);
        return containerState == OverflowState.HIDDEN ?
            OverflowState.HIDDEN : OverflowState.SCROLL;
      }
    }

    // Does not overflow any ancestor.
    return OverflowState.NONE;
  }

  function getViewportSize(win) {
    var el = win.document.documentElement;
    return { width: el.clientWidth, height: el.clientHeight };
  }

  function rect_(x, y, w, h){
    return { left: x, top: y, width: w, height: h };
  }

  function getClientRect(elem) {
    var imageMap = maybeFindImageMap_(elem);
    if (imageMap) {
      return imageMap.rect;
    } else if (elem.tagName.toUpperCase() == "HTML") {
      // Define the client rect of the <html> element to be the viewport.
      var doc = elem.ownerDocument;
      // TODO: Is this too simplified???
      var viewportSize = getViewportSize(window);
      return rect_(0, 0, viewportSize.width, viewportSize.height);
    } else {
      var nativeRect;
      try {
        nativeRect = elem.getBoundingClientRect();
      } catch (e) {
        return rect_(0, 0, 0, 0);
      }

      return rect_(nativeRect.left, nativeRect.top,
                   nativeRect.right - nativeRect.left, nativeRect.bottom - nativeRect.top);
    }
  }

  function getOpacity(elem) {
    // By default the element is opaque.
    var elemOpacity = 1;

    var opacityStyle = window.getComputedStyle(elem)["opacity"];
    if (opacityStyle) {
      elemOpacity = Number(opacityStyle);
    }

    // Let's apply the parent opacity to the element.
    var parentElement = getParentElement(elem);
    if (parentElement && parentElement.nodeType == Node.ELEMENT_NODE) {
      elemOpacity = elemOpacity * getOpacity(parentElement);
    }
    return elemOpacity;
  }

  function getAreaRelativeRect_(area) {
    var shape = area.shape.toLowerCase();
    var coords = area.coords.split(",");
    if (shape == "rect" && coords.length == 4) {
      var x = coords[0], y = coords[1];
      return rect_(x, y, coords[2] - x, coords[3] - y);
    } else if (shape == "circle" && coords.length == 3) {
      var centerX = coords[0], centerY = coords[1], radius = coords[2];
      return rect_(centerX - radius, centerY - radius, 2 * radius, 2 * radius);
    } else if (shape == "poly" && coords.length > 2) {
      var minX = coords[0], minY = coords[1], maxX = minX, maxY = minY;
      for (var i = 2; i + 1 < coords.length; i += 2) {
        minX = Math.min(minX, coords[i]);
        maxX = Math.max(maxX, coords[i]);
        minY = Math.min(minY, coords[i + 1]);
        maxY = Math.max(maxY, coords[i + 1]);
      }
      return rect_(minX, minY, maxX - minX, maxY - minY);
    }
    return rect_(0, 0, 0, 0);
  }

  function maybeFindImageMap_(elem) {
    // If not a <map> or <area>, return null indicating so.
    var elemTagName = elem.tagName.toUpperCase();
    var isMap = elemTagName == "MAP";
    if (!isMap && (elemTagName != "AREA")) {
      return null;
    }

    // Get the <map> associated with this element, or null if none.
    var map = isMap ? elem :
        ((getParentElement(elem).tagName.toUpperCase() == "MAP") ?
            getParentElement(elem) : null);

    var image = null, rect = null;
    if (map && map.name) {
      var mapDoc = map.ownerDocument;

      image = mapDoc.querySelector("*[usemap='#" + map.name + "']");

      if (image) {
        rect = getClientRect(image);
        if (!isMap && elem.shape.toLowerCase() != "default") {
          // Shift and crop the relative area rectangle to the map.
          var relRect = getAreaRelativeRect_(elem);
          var relX = Math.min(Math.max(relRect.left, 0), rect.width);
          var relY = Math.min(Math.max(relRect.top, 0), rect.height);
          var w = Math.min(relRect.width, rect.width - relX);
          var h = Math.min(relRect.height, rect.height - relY);
          rect = rect_(relX + rect.left, relY + rect.top, w, h);
        }
      }
    }

    return {image: image, rect: rect || rect_(0, 0, 0, 0)};
  }

  function getAncestor(element, matcher) {
    if (element) {
      element = getParentElement(element);
    }
    while (element) {
      if (matcher(element)) {
        return element;
      }
      element = getParentElement(element);
    }
    // Reached the root of the DOM without a match
    return null;
  }


  function isElement(node, opt_tagName) {
    // because we call this with deprecated tags such as SHADOW
    if (opt_tagName && (typeof opt_tagName !== "string")) {
      opt_tagName = opt_tagName.toString();
    }
    return !!node && node.nodeType == Node.ELEMENT_NODE &&
        (!opt_tagName || node.tagName.toUpperCase() == opt_tagName);
  }

  function getParentNodeInComposedDom(node) {
    var /**@type {Node}*/ parent = node.parentNode;

    // Shadow DOM v1
    if (parent && parent.shadowRoot && node.assignedSlot !== undefined) {
      // Can be null on purpose, meaning it has no parent as
      // it hasn't yet been slotted
      return node.assignedSlot ? node.assignedSlot.parentNode : null;
    }

    // Shadow DOM V0 (deprecated)
    if (node.getDestinationInsertionPoints) {
      var destinations = node.getDestinationInsertionPoints();
      if (destinations.length > 0) {
        return destinations[destinations.length - 1];
      }
    }

    return parent;
  }

  return function isShown(elem, opt_ignoreOpacity) {
    /**
     * Determines whether an element or its parents have `display: none` set
     * @param {!Node} e the element
     * @return {boolean}
     */
    function displayed(e) {
      if (window.getComputedStyle(e)["display"] == "none"){
        return false;
      }

      var parent = getParentNodeInComposedDom(e);

      if ((typeof ShadowRoot === "function") && (parent instanceof ShadowRoot)) {
        if (parent.host.shadowRoot !== parent) {
          // There is a younger shadow root, which will take precedence over
          // the shadow this element is in, thus this element won't be
          // displayed.
          return false;
        } else {
          parent = parent.host;
        }
      }

      if (parent && (parent.nodeType == Node.DOCUMENT_NODE ||
          parent.nodeType == Node.DOCUMENT_FRAGMENT_NODE)) {
        return true;
      }

      // Child of DETAILS element is not shown unless the DETAILS element is open
      // or the child is a SUMMARY element.
      if (parent && parent.tagName && (parent.tagName.toUpperCase() == "DETAILS") &&
          !parent.open && !(e.tagName == "SUMMARY")) {
        return false;
      }

      return parent && displayed(parent);
    }

    return isShown_(elem, !!opt_ignoreOpacity, displayed);
  };
})()
