import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = ['submenu'];

  disableCurrentNavItem() {
    const activeMenuId = this.submenuTargets.filter((item) =>
      item.classList.contains('show'),
    )[0].id;
    const activeButton = document.getElementById(`${activeMenuId}_button`);
    activeButton.setAttribute('disabled', true);
  }

  expandDropdown() {
    this.closeOtherMenus();
  }

  closeOtherMenus() {
    const expandedList = ['expand', 'show'];
    const collapsedList = ['collapse', 'hide'];

    this.submenuTargets.map((item) => {
      if (item.classList.contains('show')) {
        item.classList.remove(...expandedList);
        item.classList.add(...collapsedList);
      }
    });
  }
}
