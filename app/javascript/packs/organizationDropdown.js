import { initializeDropdown } from '@utilities/dropdownUtils';

function initDropdown() {
  const profileDropdownDiv = document.querySelector('.profile-dropdown');
  if (!profileDropdownDiv) return;

  if (profileDropdownDiv.dataset.dropdownInitialized === 'true') {
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
  if (reportAbuseLink) {
    reportAbuseLink.innerHTML = `<a href="${reportAbuseLink.dataset.path}" class="crayons-link crayons-link--block">Report Abuse</a>`;
  }

  profileDropdownDiv.dataset.dropdownInitialized = true;
}

function handleCtaOutsideClick(e) {
  const toggle = document.getElementById('header-cta-toggle');
  const menu = document.getElementById('header-cta-menu');
  if (!toggle || !menu || menu.style.display === 'none') return;

  if (!toggle.contains(e.target) && !menu.contains(e.target)) {
    menu.style.display = 'none';
    toggle.setAttribute('aria-expanded', 'false');
  }
}

function handleCtaEscapeKey(e) {
  if (e.key === 'Escape') {
    const toggle = document.getElementById('header-cta-toggle');
    const menu = document.getElementById('header-cta-menu');
    if (!toggle || !menu || menu.style.display === 'none') return;

    menu.style.display = 'none';
    toggle.setAttribute('aria-expanded', 'false');
  }
}

function initHeaderCtaDropdown() {
  const toggle = document.getElementById('header-cta-toggle');
  const menu = document.getElementById('header-cta-menu');
  if (!toggle || !menu) return;

  if (toggle.dataset.ctaInitialized === 'true') return;

  toggle.addEventListener('click', () => {
    const isOpen = menu.style.display !== 'none';
    menu.style.display = isOpen ? 'none' : 'block';
    toggle.setAttribute('aria-expanded', String(!isOpen));
  });

  if (!window._headerCtaListenersRegistered) {
    document.addEventListener('click', handleCtaOutsideClick);
    document.addEventListener('keydown', handleCtaEscapeKey);
    window._headerCtaListenersRegistered = true;
  }

  toggle.dataset.ctaInitialized = 'true';
}

function initTabsMoreDropdown() {
  const trigger = document.getElementById('org-tabs-more-trigger');
  const menu = document.getElementById('org-tabs-more-menu');
  if (!trigger || !menu) return;

  initializeDropdown({
    triggerElementId: 'org-tabs-more-trigger',
    dropdownContentId: 'org-tabs-more-menu',
  });
}

function handleTabsOverflow() {
  const nav = document.getElementById('org-tab-nav');
  if (!nav) return;

  const container = nav.querySelector('.org-custom-tabs-container');
  const dropdownMenu = nav.querySelector('#org-tabs-more-menu');
  const dropdownTrigger = nav.querySelector('.org-tabs-more-dropdown');
  
  if (!container || !dropdownMenu || !dropdownTrigger) return;

  // Move all custom page tabs from dropdown back to visible container
  const dropdownItems = Array.from(dropdownMenu.children);
  dropdownItems.forEach(item => {
    item.classList.remove('crayons-link', 'crayons-link--block');
    item.classList.add('crayons-tabs__item');
    container.appendChild(item);
  });

  dropdownTrigger.style.display = 'none';

  // Pop tabs into the dropdown while we are overflowing and have more than 1 tab (Showcase must stay)
  let attempts = 0;
  const maxAttempts = container.children.length;

  while (container.scrollWidth > container.clientWidth && container.children.length > 1 && attempts < maxAttempts) {
    dropdownTrigger.style.display = 'inline-block';
    const lastChild = container.lastElementChild;
    if (!lastChild) break;

    // Transform to dropdown item styling
    lastChild.classList.remove('crayons-tabs__item');
    lastChild.classList.add('crayons-link', 'crayons-link--block');

    // Prepend to dropdown menu to keep original order
    dropdownMenu.insertBefore(lastChild, dropdownMenu.firstChild);
    attempts++;
  }
}

function initTabs() {
  initTabsMoreDropdown();
  handleTabsOverflow();
}

function run() {
  initDropdown();
  initHeaderCtaDropdown();
  initTabs();
}

if (document.readyState !== 'loading') {
  run();
} else {
  document.addEventListener('DOMContentLoaded', run);
}

// Recalculate on resize
if (!window._orgTabsResizeRegistered) {
  window.addEventListener('resize', handleTabsOverflow);
  window._orgTabsResizeRegistered = true;
}

// Handle InstantClick page transition
if (window.InstantClick && !window._orgDropdownChangeRegistered) {
  window.InstantClick.on('change', run);
  window._orgDropdownChangeRegistered = true;
}
