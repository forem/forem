import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = [
    'submenu'
  ];

  disableCurrentNavItem(event) {
    let activeMenuId = this.submenuTargets.filter((item) => item.classList.contains("show"))[0].id
    let activeButton = event.target.getElementById(`${activeMenuId}_button`);
    activeButton.setAttribute("disabled", true)
  }

  expandDropdown(event) {
    this.redirectToFirstChildNavItem();
    this.closeOtherMenus();
  }

  redirectToFirstChildNavItem() {
    window.location.href = event.target.getAttribute('data-target-href');
  }

  closeOtherMenus() {
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
