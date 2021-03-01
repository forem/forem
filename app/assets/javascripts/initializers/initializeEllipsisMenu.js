// SUBMITTING FORM //

function getFormValues(form) {
  var articleId = form.action.match(/\/(\d+)$/)[1];
  var inputs = form.getElementsByTagName('input');
  var formData = { id: articleId, article: {} };

  for (var i = 0; i < inputs.length; i += 1) {
    var input = inputs[i];
    var name = input.getAttribute('name');
    var value = input.getAttribute('value');

    if (name.match(/\[(.*)\]/)) {
      var key = name.match(/\[(.*)\]$/)[1];
      formData.article[key] = value;
    } else {
      formData[name] = value;
    }
  }

  return formData;
}

function toggleArchived(article, needsArchived) {
  if (needsArchived === 'true') {
    article.classList.add('story-archived', 'hidden');
  } else {
    article.classList.remove('story-archived');
  }
}

function toggleNotifications(submit, action) {
  if (action === 'Mute Notifications') {
    submit.setAttribute('value', 'Receive Notifications');
  } else {
    submit.setAttribute('value', 'Mute Notifications');
  }
}

function onXhrSuccess(form, article, values) {
  if (values.article.archived) {
    toggleArchived(article, values.article.archived);
  } else {
    var submit = form.querySelector('[type="submit"]');
    var submitValue = submit.getAttribute('value');

    toggleNotifications(submit, submitValue);
  }

  article.getElementsByClassName('js-ellipsis-menu')[0].classList.add('hidden');
}

function handleFormSubmit(e) {
  e.preventDefault();
  e.stopPropagation();

  var form = e.target;
  var values = getFormValues(form);
  var data = JSON.stringify(values);

  var formData = new FormData(form);
  var method = formData.get('_method') || 'post';

  var xhr = new XMLHttpRequest();
  xhr.open(method.toUpperCase(), form.action);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(data);

  xhr.onload = function onload() {
    var article = form.closest('.js-dashboard-story');

    if (xhr.status === 200) {
      onXhrSuccess(form, article, values);
      var message =
        values.commit === 'Mute Notifications'
          ? 'Notifications Muted'
          : 'Notifications Restored';
      article.getElementsByClassName(
        'js-dashboard-story-details',
      )[0].innerHTML = message;
    } else {
      article.getElementsByClassName(
        'js-dashboard-story-details',
      )[0].innerHTML = 'Failed to update article.';
    }
  };
}

function initializeFormSubmit() {
  var forms = document.querySelectorAll(
    '.js-ellipsis-menu-dropdown .js-archive-toggle',
  );

  for (var i = 0; i < forms.length; i += 1) {
    forms[i].addEventListener('submit', handleFormSubmit);
  }
}

// TOGGLING MENU //

function getMenu(el) {
  var parentDiv = el.closest('.js-ellipsis-menu');
  var menu = parentDiv.getElementsByClassName('js-ellipsis-menu-dropdown')[0];

  return menu;
}

function hideIfNotAlreadyHidden(menu) {
  if (menu.classList.contains('block')) {
    menu.classList.remove('block');
  }
}

function hideAllEllipsisMenusExcept(menu) {
  var menus = document.getElementsByClassName('js-ellipsis-menu-dropdown');

  for (var i = 0; i < menus.length; i += 1) {
    if (menus[i] !== menu) {
      hideIfNotAlreadyHidden(menus[i]);
    }
  }
}

function hideEllipsisMenus(e) {
  if (!e.target.closest('.js-ellipsis-menu')) {
    var menus = document.getElementsByClassName('js-ellipsis-menu-dropdown');

    for (var i = 0; i < menus.length; i += 1) {
      hideIfNotAlreadyHidden(menus[i]);
    }
  }
}

function toggleEllipsisMenu(e) {
  var menu = getMenu(e.target);

  // Make sure other ellipsis menus close when a new one
  // is opened
  hideAllEllipsisMenusExcept(menu);

  if (menu.classList.contains('block')) {
    menu.classList.remove('block');
  } else {
    menu.classList.add('block');
  }
}

function initializeEllipsisMenuToggle() {
  var buttons = document.getElementsByClassName('js-ellipsis-menu-trigger');

  for (var i = 0; i < buttons.length; i += 1) {
    buttons[i].addEventListener('click', toggleEllipsisMenu);
  }

  // Hide ellipsis menus when you click outside of the ellipsis menu parent div
  const body = document.body;
  if (body) {
    body.addEventListener('click', hideEllipsisMenus);
  }
}

function initializeEllipsisMenu() {
  initializeEllipsisMenuToggle();
  initializeFormSubmit();
}
