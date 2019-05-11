function getMenu(el) {
  var parentDiv = el.closest('div.ellipsis-menu');
  var menu = parentDiv.querySelector('ul.ellipsis-menu');
  return menu;
}

function hideAllEllipsisMenusExcept(menu) {
  var menus = document.querySelectorAll('ul.ellipsis-menu');

  for (var i = 0; i < menus.length; i += 1) {
    if (menus[i] !== menu && !menus[i].classList.contains('hidden')) {
      menus[i].classList.add('hidden');
    }
  }
}

function toggleEllipsisMenu(e) {
  var menu = getMenu(e.target);

  // Make sure other ellipsis menus close when a new one
  // is opened
  hideAllEllipsisMenusExcept(menu);

  if (menu.classList.contains('hidden')) {
    menu.classList.remove('hidden');
  } else {
    menu.classList.add('hidden');
  }
}

function initializeEllipsisMenu() {
  var buttons = document.getElementsByClassName('ellipsis-menu-btn');

  for (var i = 0; i < buttons.length; i += 1) {
    buttons[i].addEventListener('click', toggleEllipsisMenu);
  }
}
