import Element from './element.js';
import { EMPTY_STRING, KEY_CODE } from '../consts.js';
import { hasClass, addClass, removeClass, getPaddingTop, getFullHeight, xssEscape } from '../utils.js';

const MESSAGE_PREFIX = ' : ';
const LAST_MESSAGE_YESTERDAY = 'YESTERDAY';
const MORE_MESSAGE_BELOW = 'More message below.';

const MAX_HEIGHT_INPUT_OUTER = 50;
const MAX_HEIGHT_INPUT_INNER = 39;
const MIN_HEIGHT_INPUT_INNER = 14;

class MessageBoard extends Element{
  constructor() {
    super();
    this._create();
    this.senderColor = {};
    this.kr = null;
  }

  reset() {
    this.senderColor = {};
    this.kr = null;
  }

  _create() {
    let board = this._createDiv();
    this._setClass(board, [this.classes.MESSAGE_BOARD]);

    let content = this._createDiv();
    this._setClass(content, [this.classes.CONTENT]);
    board.appendChild(content);

    let contentInput = this._createDiv();
    this._setClass(contentInput, [this.classes.CONTENT_INPUT]);

    let input = this._createDiv();
    this._setClass(input, [this.classes.INPUT]);
    input.setAttribute('contenteditable', true);
    this._setFocusEvent(input, () => {
      if (!hasClass(contentInput, this.classes.ACTIVE)) {
        addClass(contentInput, this.classes.ACTIVE);
      }
    });
    this._setFocusOutEvent(input, () => {
      if (hasClass(contentInput, this.classes.ACTIVE)) {
        removeClass(contentInput, this.classes.ACTIVE);
      }
    });
    this._setKeydownEvent(input, (event) => {
      this._responsiveTextInput();
      if (event.keyCode == KEY_CODE.KR) {
        this.kr = this.input.textContent;
      }
      if (event.keyCode == KEY_CODE.ENTER && !event.shiftKey) {
        event.preventDefault();
        this.icon.click();
        this.clearInput();
      }
    });
    this._setKeyupEvent(input, () => {
      this._responsiveTextInput();
    });
    this._setPasteEvent(input, (event) => {
      let clipboardData;
      let pastedData;

      event.stopPropagation();
      event.preventDefault();

      clipboardData = event.clipboardData || window.clipboardData;
      pastedData = clipboardData.getData('Text');

      input.textContent += pastedData;
    });
    contentInput.appendChild(input);

    let icon = this._createDiv();
    this._setClass(icon, [this.classes.ICON]);
    contentInput.appendChild(icon);

    board.appendChild(contentInput);

    this.self = board;
    this.content = content;
    this.input = input;
    this.icon = icon;
  }

  getMessage() {
    if (this.input.textContent || this.kr) {
      let textMessage = this.input.textContent || this.kr;
      return textMessage.trim();
    }
  }

  clearInput() {
    let items = this.input.querySelectorAll(this.tags.DIV);
    for (var i = 0 ; i < items.length ; i++) {
      let item = items[i];
      item.remove();
    }
    this._setContent(this.input, EMPTY_STRING);
    this.kr = null;
    this._iconToggle();
  }

  iconClickEvent(action) {
    this._setClickEvent(this.icon, action);
  }

  _responsiveTextInput() {
    let outerHeight = this.input.scrollHeight;
    let paddingTop = getPaddingTop(this.input);
    let innerHeight = (outerHeight - (paddingTop * 2));
    let expectPadding = (MAX_HEIGHT_INPUT_OUTER - innerHeight);

    if (innerHeight < MIN_HEIGHT_INPUT_INNER) {
      this._setPaddingTopBottom(this.input, ((MAX_HEIGHT_INPUT_OUTER - MIN_HEIGHT_INPUT_INNER)/2));
    } else if (innerHeight > MAX_HEIGHT_INPUT_INNER) {
      this._setPaddingTopBottom(this.input, ((MAX_HEIGHT_INPUT_OUTER - MAX_HEIGHT_INPUT_INNER)/2));
    } else {
      this._setPaddingTopBottom(this.input, (expectPadding/2));
    }
    this._iconToggle();
  }

  _iconToggle() {
    if (this.input.textContent.length > 0) {
      if (!hasClass(this.icon, this.classes.ACTIVE)) {
        addClass(this.icon, this.classes.ACTIVE);
      }
    } else {
      removeClass(this.icon, this.classes.ACTIVE);
    }
  }

  setScrollEvent(action) {
    let _self = this;
    _self._setScrollEvent(_self.content, () => {
      if (_self.content.scrollTop == 0) {
        action();
      }
      if (_self.isBottom()) {
        this._removeToBottomBtn();
      }
    });
  }

  renderMessage(messageList, isScrollToBottom, isLoadMore) {
    let firstChild = this.content.firstChild;
    var moveScroll = 0;
    var i;
    for (i = 0 ; i < messageList.length ; i++) {
      let message = messageList[i];
      if (message.isUserMessage()) {
        let item = this._createMessageItem(message);
        isLoadMore ? this.content.insertBefore(item, firstChild) : this.content.appendChild(item);
        moveScroll += getFullHeight(item);
      } else {
        // do something...
      }
    }
    if (isLoadMore) {
      this.content.scrollTop = moveScroll;
    }
    if (isScrollToBottom) {
      this._scrollToBottom();
    }
  }

  _createMessageItem(message) {
    let item = this._createDiv();
    this._setClass(item, [this.classes.MESSAGE_ITEM]);
    item.setAttribute('id', message.messageId);

    let text = this._createDiv();
    this._setClass(text, [this.classes.MESSAGE_TEXT]);

    let nickname = this._createLabel();
    let nicknameColor = this.senderColor[message.sender.userId];
    if (!nicknameColor) {
      nicknameColor = Math.floor((Math.random() * 12) + 1);
      nicknameColor = (nicknameColor < 10) ? '0' + nicknameColor.toString() : nicknameColor.toString();
      this.senderColor[message.sender.userId] = nicknameColor;
    }
    this._setClass(nickname, [this.classes.NICKNAME, this.classes.NICKNAME_COLOR + nicknameColor]);
    this._setContent(nickname, xssEscape(message.sender.nickname));

    text.appendChild(nickname);
    this._addContent(text, MESSAGE_PREFIX + xssEscape(message.message));

    item.appendChild(text);

    let time = this._createDiv();
    this._setClass(time, [this.classes.TIME]);
    this._setContent(time, this._getTime(message));
    item.appendChild(time);

    return item;
  }

  createBottomBtn() {
    let btn = this._createDiv();
    this._setClass(btn, [this.classes.BTN]);
    this._setContent(btn, MORE_MESSAGE_BELOW);
    if (!this.bottomBtn) {
      this.self.appendChild(btn);
      this.bottomBtn = btn;
    }
    this._setClickEvent(btn, () => {
      this._scrollToBottom();
      this._removeToBottomBtn();
    });
  }

  _removeToBottomBtn() {
    if (this.bottomBtn) {
      this.self.removeChild(this.bottomBtn);
      this.bottomBtn = null;
    }
  }

  isBottom() {
    return this.content.scrollTop == this.content.scrollHeight - this.content.clientHeight;
  }

  _scrollToBottom() {
    this.content.scrollTop = this.content.scrollHeight - this.content.clientHeight;
  }

  _getTime(message) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY',
      'JUN', 'JUL', 'AUG', 'SEP', 'OCT',
      'NOV', 'DEC'
    ];

    var _getDay = (val) => {
      let day = parseInt(val);
      if (day == 1) {
        return day + 'st';
      } else if (day == 2) {
        return day + 'en';
      } else if (day == 3) {
        return day + 'rd';
      } else {
        return day + 'th';
      }
    };

    var _checkTime = (val) => {
      return (+val < 10) ? '0' + val : val;
    };

    if (message) {
      var _nowDate = new Date();
      var _date = new Date(message.createdAt);
      if (_nowDate.getDate() - _date.getDate() == 1) {
        return LAST_MESSAGE_YESTERDAY;
      } else if (_nowDate.getFullYear() == _date.getFullYear()
        && _nowDate.getMonth() == _date.getMonth()
        && _nowDate.getDate() == _date.getDate()) {
        return _checkTime(_date.getHours()) + ':' + _checkTime(_date.getMinutes());
      } else {
        return months[_date.getMonth()] + ' ' + _getDay(_date.getDate());
      }
    }
    return '';
  }

}

export { MessageBoard as default };
