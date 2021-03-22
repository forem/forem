import { Application } from 'stimulus';
import SidebarController from '../../controllers/sidebar_controller';

describe('SidebarController', () => {
  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
  });

  beforeEach(() => {
    document.body.innerHTML = `
    <div class="admin__left-sidebar crayons-layout__left-sidebar" data-controller="sidebar" data-action="load@window->sidebar#disableCurrentNavItem">
      <nav class="hidden m:block">
        <ul>
          <li>
              <a class="crayons-link crayons-link--block " href="/admin/permissions" aria-page="" data-action="click->sidebar#expandDropdown">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" class="dropdown-icon crayons-icon" role="img"><path d="M4 22a8 8 0 1 1 16 0h-2a6 6 0 1 0-12 0H4zm8-9c-3.315 0-6-2.685-6-6s2.685-6 6-6 6 2.685 6 6-2.685 6-6 6zm0-2c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4z"></path></svg>
                Admin Team
              </a>
          </li>
          <li>
            <button class="crayons-link crayons-link--block cursor-pointer " id="advanced_button" data-toggle="collapse" data-target="#advanced" data-target-href="/admin/advanced/broadcasts" aria-expanded="false" aria-controls="advanced" data-action="click->sidebar#expandDropdown">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" class="dropdown-icon crayons-icon" role="img"><path d="M13 9h8L11 24v-9H4l9-15v9zm-2 2V7.22L7.532 13H13v4.394L17.263 11H11z"></path></svg>
              Advanced
            </button>
            <ul id="advanced" data-sidebar-target="submenu" class="collapse hide">
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/advanced/broadcasts" aria-page="">
                  Broadcasts
                </a>
              </li>
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/advanced/response_templates" aria-page="">
                  Response Templates
                </a>
              </li>
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/advanced/sponsorships" aria-page="">
                  Sponsorships
                </a>
              </li>
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/advanced/tools" aria-page="">
                  Developer Tools
                </a>
              </li>
            </ul>
          </li>
          <li>
            <button class="crayons-link crayons-link--block cursor-pointer crayons-link--current" id="apps_button" data-toggle="collapse" data-target="#apps" data-target-href="/admin/apps/chat_channels" aria-expanded="true" aria-controls="apps" data-action="click->sidebar#expandDropdown">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" class="dropdown-icon crayons-icon" role="img"><path d="M12 2c5.522 0 10 3.978 10 8.889a5.558 5.558 0 0 1-5.556 5.555h-1.966c-.922 0-1.667.745-1.667 1.667 0 .422.167.811.422 1.1.267.3.434.689.434 1.122C13.667 21.256 12.9 22 12 22 6.478 22 2 17.522 2 12S6.478 2 12 2zm-1.189 16.111a3.664 3.664 0 0 1 3.667-3.667h1.966A3.558 3.558 0 0 0 20 10.89C20 7.139 16.468 4 12 4a8 8 0 0 0-.676 15.972 3.648 3.648 0 0 1-.513-1.86zM7.5 12a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm9 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zM12 9a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z"></path></svg>

              Apps
            </button>
            <ul id="apps" data-sidebar-target="submenu" class="expand show">
              <li>
                <a class="crayons-link crayons-link--block ml-7 fw-bold" href="/admin/apps/chat_channels" aria-page="page">
                  Chat Channels
                </a>
              </li>
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/apps/events" aria-page="">
                  Events
                </a>
              </li>
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/apps/listings" aria-page="">
                  Listings
                </a>
              </li>
              <li>
                <a class="crayons-link crayons-link--block ml-7 " href="/admin/apps/welcome" aria-page="">
                  Welcome
                </a>
              </li>
            </ul>
          </li>
        </ul>
      </nav>
    </div>`;

    const application = Application.start();
    application.register('sidebar', SidebarController);
  });

  describe('#disableCurrentNavItem', () => {
    it('sets the disabled attribute on the open menu button', () => {
      window.dispatchEvent(new Event('load'))
      const button = document.getElementById('apps_button');

      expect(button.getAttribute("disabled")).toEqual("true");
    });
  });

  describe('#expandDropdown', () => {
    beforeEach(() => {
      let assignMock = jest.fn();

      delete window.location;
      window.location = { href: assignMock };
    });

    afterEach(() => {
      window.location = location;
    });

    it('redirects to the first child navigation item', () => {
      const button = document.getElementById('advanced_button');
      button.click();

      expect(window.location.href).toEqual("/admin/advanced/broadcasts")
    });

    it('closes other menu items', () => {
      const button = document.getElementById('advanced_button');
      button.click();

      expect(document.getElementById('apps').classList).toContain("hide");
    });

  })
});
