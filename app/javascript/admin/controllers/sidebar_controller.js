import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = ['submenu'];

  expandDropdown(event) {
    if (
      event.target.getAttribute('data-target-href') !== window.location.pathname
    ) {
      this.redirectToFirstChildNavItem(event);
    }
    this.closeOtherMenus();
  }

  redirectToFirstChildNavItem(event) {
    window.location.href = event.target.getAttribute('data-target-href');
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
