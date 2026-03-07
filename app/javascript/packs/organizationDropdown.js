import { initializeDropdown } from '@utilities/dropdownUtils';

function initDropdown() {
  const profileDropdownDiv = document.querySelector('.profile-dropdown');

  if (profileDropdownDiv.dataset.dropdownInitialized === 'true') {
    return;
  }

  if (!profileDropdownDiv) {
    return;
  }

  initializeDropdown({
    triggerElementId: 'organization-profile-dropdown',
    dropdownContentId: 'organization-profile-dropdownmenu',
  });

  // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
  const reportAbuseLink = profileDropdownDiv.querySelector(
    '.report-abuse-link-wrapper',
  );
  reportAbuseLink.innerHTML = `<a href="${reportAbuseLink.dataset.path}" class="crayons-link crayons-link--block">Report Abuse</a>`;

  profileDropdownDiv.dataset.dropdownInitialized = true;
}

function initHeaderCtaDropdown() {
  const toggle = document.getElementById('header-cta-toggle');
  const menu = document.getElementById('header-cta-menu');
  if (!toggle || !menu) return;

  toggle.addEventListener('click', () => {
    const isOpen = menu.style.display !== 'none';
    menu.style.display = isOpen ? 'none' : 'block';
    toggle.setAttribute('aria-expanded', String(!isOpen));
  });

  document.addEventListener('click', (e) => {
    if (!toggle.contains(e.target) && !menu.contains(e.target)) {
      menu.style.display = 'none';
      toggle.setAttribute('aria-expanded', 'false');
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      menu.style.display = 'none';
      toggle.setAttribute('aria-expanded', 'false');
    }
  });
}

initDropdown();
initHeaderCtaDropdown();
