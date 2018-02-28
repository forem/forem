import { EMPTY_STRING } from '../consts.js';
import Element from './element.js';

class Spinner extends Element {
  constructor() {
    super();
    this._create();
  }

  _create() {
    let spinner = this._createDiv();
    this._setClass(spinner, [this.classes.SPINNER]);
    var i;
    for (i = 0 ; i < 3 ; i++) {
      spinner.appendChild(this._createDiv());
    }
    this.self = spinner;
  }

  insert(target) {
    this._setContent(target, EMPTY_STRING);
    target.appendChild(this.self);
  }

  remove(target) {
    if (target.firstElementChild) {
      target.removeChild(this.self);
    }
  }
}

export { Spinner as default };
