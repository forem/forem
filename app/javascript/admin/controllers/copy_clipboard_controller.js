/* global Runtime */
import { Controller } from 'stimulus';
export default class CopyClipboardController extends Controller {
  handleCopyClick() {
    const inputValue = document.getElementById('settings-org-secret').value;
    Runtime.copyToClipboard(inputValue);
  }
}
