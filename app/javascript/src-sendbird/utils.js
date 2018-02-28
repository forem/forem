const DISPLAY_NONE = 'none';
const DISPLAY_BLOCK = 'block';

export function hide(target) {
  if (target) {
    target.style.display = DISPLAY_NONE;
  }
}

export function show(target, displayType) {
  if (target) {
    displayType ? target.style.display = displayType : target.style.display = DISPLAY_BLOCK;
  }
}

export function hasClass(target, className) {
  if (target.classList) {
    return target.classList.contains(className);
  } else {
    return new RegExp('(^| )' + className + '( |$)', 'gi').test(target.className);
  }
}

export function addClass(target, className) {
  if (target.classList) {
    if (!(className in target.classList)) {
      target.classList.add(className);
    }
  } else {
    if (target.className.indexOf(className) < 0) {
      target.className += ' ' + className;
    }
  }
  return target;
}

export function removeClass(target, className) {
  if (target.classList) {
    target.classList.remove(className);
  } else {
    target.className = target.className.replace(new RegExp('(^|\\b)' + className.split(' ').join('|') + '(\\b|$)', 'gi'), '');
  }
  return target;
}

export function isEmptyString(target) {
  return !!(target == null || target == undefined || target.length == 0);
}

export function getFullHeight(target) {
  var height = target.offsetHeight;
  var style = getComputedStyle(target);
  height += parseInt(style.marginTop) + parseInt(style.marginBottom);
  return height;
}

export function getPaddingTop(target) {
  try {
    return parseFloat(window.getComputedStyle(target, null).getPropertyValue('padding-top'));
  } catch(e) {
    return parseFloat(target.currentStyle.paddingTop);
  }
}

export function xssEscape(target) {
  if (typeof target === 'string') {
    return target
      .split('&').join('&amp;')
      .split('#').join('&#35;')
      .split('<').join('&lt;')
      .split('>').join('&gt;')
      .split('"').join('&quot;')
      .split('\'').join('&apos;')
      .split('+').join('&#43;')
      .split('-').join('&#45;')
      .split('(').join('&#40;')
      .split(')').join('&#41;')
      .split('%').join('&#37;');
  } else {
    return target;
  }
}
