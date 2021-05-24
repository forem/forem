const openDropdown = (triggerElement, dropdownContent) => {
  triggerElement.setAttribute('aria-expanded', 'true');
  // Crayons dropdowns have display: none by default, this overrides it
  dropdownContent.classList.add('block');

  // TODO: focus some stuff
};

const closeDropdown = (triggerElement, dropdownContent) => {
  triggerElement.setAttribute('aria-expanded', 'false');
  dropdownContent.classList.remove('block');
};

// todo - probably need a generic 'toggle' dropdown function that detects if we're opening or closing, and performs the right action

const toggleDropdown = (triggerElement, dropdownContent) => {
  const isAlreadyOpen = triggerElement.getAttribute('aria-expanded') === 'true';
  if (isAlreadyOpen) {
    closeDropdown(triggerElement, dropdownContent);
  } else {
    openDropdown(triggerElement, dropdownContent);
  }
};

export const initializeDropdown = ({
  triggerButtonElementId,
  dropdownContentElementId,
}) => {
  const triggerButton = document.getElementById(triggerButtonElementId);
  const dropdownContent = document.getElementById(dropdownContentElementId);

  if (!triggerButton || !dropdownContent) {
    // The required props haven't been provided, do nothing
    return;
  }

  //   These may have already been declared on the element, but this makes sure we catch any where the attribute is missing
  triggerButton.setAttribute('aria-expanded', 'false');
  triggerButton.setAttribute('aria-controls', dropdownContentElementId);
  //   TODO: haspopup?

  triggerButton.addEventListener('click', () =>
    toggleDropdown(triggerButton, dropdownContent),
  );
};
