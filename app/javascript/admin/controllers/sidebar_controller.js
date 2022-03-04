import { Controller } from '@hotwired/stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = ['submenu'];

  disableCurrentNavItem() {
    if (this.submenuTargets.length > 0) {
      const activeMenuId = this.submenuTargets.filter((item) =>
        item.classList.contains('show'),
      )[0]?.id;

      if (activeMenuId) {
        const activeButton = document.getElementById(`${activeMenuId}_button`);
        activeButton.setAttribute('disabled', true);
      }
    }
  }

  expandDropdown() {
    this.closeOtherMenus();
  }

  closeOtherMenus() {
    this.submenuTargets.map((item) => {
      if (item.classList.contains('show')) {
        item.classList.remove('show');
      }
    });
  }
}
