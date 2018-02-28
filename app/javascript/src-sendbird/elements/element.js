// import '../../scss/chat.scss';

class Element {
  constructor() {
    this.tags = {
      DIV: 'div',
      SPAN: 'span',
      INPUT: 'input',
      LABEL: 'label'
    };
    this.events = {
      CLICK: 'click',
      KEYDOWN: 'keydown',
      KEYUP: 'keyup',
      SCROLL: 'scroll',
      PASTE: 'paste',
      CHANGE: 'change',
      FOCUS: 'focus',
      FOCUSOUT: 'focusout'
    };
    this.classes = {
      SPINNER: 'sb-spinner',

      CHAT_BOARD: 'chat-board',
      LOGIN_BOARD: 'login-board',
      MESSAGE_BOARD: 'message-board',
      MESSAGE_ITEM: 'message-item',
      MESSAGE_TEXT: 'message-text',

      INPUT_TEXT: 'input-text',
      CONTENT_INPUT: 'content-input',
      INPUT: 'input',

      CONTENT: 'content',
      TOP: 'top',
      BTN: 'btn',
      TIME: 'time',
      ICON: 'icon',

      DISABLED: 'disabled',
      ACTIVE: 'active',

      USER_ID: 'user-id',
      NICKNAME: 'nickname',
      NICKNAME_COLOR: 'nickname-color-'
    };
  }

  _createDiv() {
    return document.createElement(this.tags.DIV);
  }

  _createSpan() {
    return document.createElement(this.tags.SPAN);
  }

  _createInput() {
    return document.createElement(this.tags.INPUT);
  }

  _createLabel() {
    return document.createElement(this.tags.LABEL);
  }

  _setClass(...args) {
    args.reduce((target, classes) => {
      return target.className += classes.join(' ');
    });
  }

  _setContent(target, text) {
    target.innerHTML = text;
  }

  _addContent(target, text) {
    target.innerHTML += text;
  }

  _setClickEvent(target, action) {
    target.addEventListener(this.events.CLICK, () => {
      action();
    });
  }

  _setScrollEvent(target, action) {
    target.addEventListener(this.events.SCROLL, () => {
      action();
    });
  }

  _setPasteEvent(target, action) {
    target.addEventListener(this.events.PASTE, (event) => {
      action(event);
    });
  }

  _setKeyupEvent(target, action) {
    target.addEventListener(this.events.KEYUP, (event) => {
      action(event);
    });
  }

  _setKeydownEvent(target, action) {
    target.addEventListener(this.events.KEYDOWN, (event) => {
      action(event);
    });
  }

  _setChangeEvent(target, action) {
    target.addEventListener(this.events.CHANGE, () => {
      action();
    });
  }

  _setFocusEvent(target, action) {
    target.addEventListener(this.events.FOCUS, () => {
      action();
    });
  }

  _setFocusOutEvent(target, action) {
    target.addEventListener(this.events.FOCUSOUT, () => {
      action();
    });
  }

  _setHeight(target, height) {
    target.style.height = height + 'px';
  }

  _setPaddingTopBottom(target, padding) {
    target.style.paddingTop = padding + 'px';
    target.style.paddingBottom = padding + 'px';
  }
}

export { Element as default };
