import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = [
    'submenu'
  ];

  expandDropdown(event) {
    console.log("in here");
    // dont reopen teh current menu
    // event.target.getAttribute('data-target');
    // debugger
    this.submenuTargets.map((item) => {
      if(item.classList.contains("show")) {
        item.classList.remove("show");
      }
    });
  }
}
