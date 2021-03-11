import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = [
    'submenu'
  ];

  expandDropdown(event) {
    window.location.href = event.target.getAttribute('data-target-href');

    this.submenuTargets.map((item) => {
      if(item.classList.contains("show")) {
        const expandedList = ['expand', 'show'];
        item.classList.remove(...expandedList);

        const collapsedList = ['collapse', 'hide'];
        item.classList.add(...collapsedList);
      }
    });
  }
}
