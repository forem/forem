import Element from './element.js';

import { EMPTY_STRING, CURSOR, KEY_CODE } from '../consts.js';
import { removeClass, addClass, hasClass, isEmptyString } from '../utils.js';

const TEXT_INPUT_USER_ID = 'USER ID';
const TEXT_INPUT_NICKNAME = 'NICKNAME';
const TEXT_LOIN_BTN = 'Start Chat';

class LoginBoard extends Element {
  constructor(board) {
    super();
    this._create();
    board.appendChild(this.self);
  }

  reset() {
    this.userId.disabled = false;
    this.userId.value = EMPTY_STRING;
    this.nickname.disabled = false;
    this.nickname.value = EMPTY_STRING;
    this._setContent(this.loginBtn, TEXT_LOIN_BTN);
    this.loginBtnToggle(false);
  }

  _create() {
    let board = this._createDiv();
    this._setClass(board, [this.classes.LOGIN_BOARD]);

    let userIdDiv = this._createDiv();
    this._setClass(userIdDiv, [this.classes.CONTENT, this.classes.USER_ID]);

    let userIdText = this._createDiv();
    this._setClass(userIdText, [this.classes.INPUT_TEXT]);
    this._setContent(userIdText, TEXT_INPUT_USER_ID);
    userIdDiv.appendChild(userIdText);

    let userIdInput = this._createInput();
    this._setClass(userIdInput, [this.classes.INPUT]);
    userIdDiv.appendChild(userIdInput);

    board.appendChild(userIdDiv);

    let nicknameDiv = this._createDiv();
    this._setClass(nicknameDiv, [this.classes.CONTENT, this.classes.NICKNAME]);

    let nicknameText = this._createDiv();
    this._setClass(nicknameText, [this.classes.INPUT_TEXT]);
    this._setContent(nicknameText, TEXT_INPUT_NICKNAME);
    nicknameDiv.appendChild(nicknameText);

    let nicknameInput = this._createInput();
    this._setClass(nicknameInput, [this.classes.INPUT]);
    nicknameDiv.appendChild(nicknameInput);

    board.appendChild(nicknameDiv);

    let loginBtn = this._createDiv();
    this._setClass(loginBtn, [this.classes.BTN, this.classes.DISABLED]);
    this._setContent(loginBtn, TEXT_LOIN_BTN);

    board.appendChild(loginBtn);
    this.self = board;
    this.userId = userIdInput;
    this.nickname = nicknameInput;
    this.loginBtn = loginBtn;

    this._setEvents();
  }

  _checkEnableLoginBtn() {
    if (!isEmptyString(this.userId.value.trim()) && !isEmptyString(this.nickname.value.trim())) {
      removeClass(this.loginBtn, this.classes.DISABLED);
    } else {
      if (!hasClass(this.loginBtn, this.classes.DISABLED)) {
        addClass(this.loginBtn, this.classes.DISABLED);
      }
    }
  }

  _setEvents() {
    let userIdEvent = (event) => {
      if (event && event.keyCode == KEY_CODE.ENTER) {
        this.nickname.focus();
      } else {
        this._checkEnableLoginBtn();
      }
    };
    let nicknameEvent = (event) => {
      if (event && event.keyCode == KEY_CODE.ENTER) {
        if (!hasClass(this.loginBtn, this.classes.DISABLED)) {
          this.loginBtn.click();
        }
      } else {
        this._checkEnableLoginBtn();
      }
    };

    this._setKeyupEvent(this.userId, (event) => { userIdEvent(event); });
    this._setChangeEvent(this.userId, () => { userIdEvent(); });
    this._setKeyupEvent(this.nickname, (event) => { nicknameEvent(event); });
    this._setChangeEvent(this.nickname, () => { nicknameEvent(); });
  }

  addLoginBtnClickEvent(action) {
    this._setClickEvent(this.loginBtn, action);
  }

  disableLoginBoard() {
    this.userId.disabled = true;
    this.nickname.disabled = true;
    addClass(this.loginBtn, this.classes.DISABLED);
  }

  loginBtnToggle(isEnabled) {
    if (isEnabled || isEnabled === undefined) {
      removeClass(this.loginBtn, this.classes.DISABLED);
      this.loginBtn.style.cursor = CURSOR.INIT;
    } else {
      addClass(this.loginBtn, this.classes.DISABLED);
      this.loginBtn.style.cursor = CURSOR.DEFAULT;
    }
  }

}

export { LoginBoard as default };
