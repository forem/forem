import { initializeDropdown } from '@utilities/dropdownUtils';
import { waitOnBaseData } from '@utilities/waitOnBaseData';

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

function initOrgAdminButtons() {
  const settingsBtn = document.getElementById('org-settings-btn');
  const adminBtn = document.getElementById('org-admin-btn');
  
  if (!settingsBtn && !adminBtn) return;
  
  const orgId = Number(settingsBtn ? settingsBtn.dataset.orgId : adminBtn.dataset.orgId);
  if (!orgId) return;

  waitOnBaseData().then(() => {
    const userStr = document.body.dataset.user;
    if (!userStr) return;
    
    try {
      const currentUser = JSON.parse(userStr);
      const isAdmin = currentUser.admin;
      const isOrgAdmin = currentUser.admin_organization_ids?.includes(orgId);
      
      if (settingsBtn && isOrgAdmin) {
        settingsBtn.classList.remove('hidden');
      }
      
      if (adminBtn && isAdmin) {
        adminBtn.classList.remove('hidden');
      }
    } catch (e) {
      console.error("Failed to parse current user for organization settings", e);
    }
  });
}

initDropdown();
initHeaderCtaDropdown();
initOrgAdminButtons();
