import Element from './element.js';
import { TITLE_BOARD_TOP } from '../consts.js';

class ChatBoard extends Element {
  constructor(chat) {
    super();
    this._create();
    chat.appendChild(this.self);
  }

  reset() {
  }

  _create() {
    let board = this._createDiv();
    this._setClass(board, [this.classes.CHAT_BOARD]);

    let top = this._createDiv();
    this._setClass(top, [this.classes.TOP]);
    this._setContent(top, TITLE_BOARD_TOP);

    board.appendChild(top);
    this.self = board;
  }
}

export { ChatBoard as default };
