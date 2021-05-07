import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class SidebarController extends Controller {
  static targets = ['submenu', 'menuItem'];

  connect() {
    // expand the <details> menu that has as a selected item
    const activeMenuItem = this.menuItemTargets.filter((item) =>
      item.classList.contains('active'),
    )[0];
    activeMenuItem?.parentNode?.parentNode?.setAttribute('open', '');
  }

  // disableCurrentNavItem() {
  //   if (this.submenuTargets.length > 0) {
  //     const activeMenuId = this.submenuTargets.filter((item) =>
  //       item.classList.contains('show'),
  //     )[0]?.id;

  //     if (activeMenuId) {
  //       const activeButton = document.getElementById(`${activeMenuId}_button`);
  //       activeButton.setAttribute('disabled', true);
  //     }
  //   }
  // }

  // expandDropdown() {
  //   this.closeOtherMenus();
  // }

  // closeOtherMenus() {
  //   this.submenuTargets.map((item) => {
  //     if (item.classList.contains('show')) {
  //       item.classList.remove('show');
  //     }
  //   });
  // }
}
