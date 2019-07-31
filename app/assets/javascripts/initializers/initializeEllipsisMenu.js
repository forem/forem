// SUBMITTING FORM //

function getFormValues(form) {
  var articleId = form.action.match(/\/(\d+)$/)[1];
  var inputs = form.querySelectorAll('input');
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
    article.classList.add('single-article-archived', 'hidden');
  } else {
    article.classList.remove('single-article-archived');
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
    var submit = form.querySelector('input[type="submit"]');
    var submitValue = submit.getAttribute('value');

    toggleNotifications(submit, submitValue);
  }

  article.querySelector('ul.ellipsis-menu').classList.add('hidden');
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
    var article = form.closest('div.single-article');

    if (xhr.status === 200) {
      onXhrSuccess(form, article, values);
      var message =
        values.commit === 'Mute Notifications'
          ? 'Notifications Muted'
          : 'Notifications Restored';
      article.querySelector('.dashboard-meta-details').innerHTML = message;
    } else {
      article.querySelector('.dashboard-meta-details').innerHTML =
        'Failed to update article.';
    }
  };
}

function initializeFormSubmit() {
  var forms = document.querySelectorAll('ul.ellipsis-menu > li > form');

  for (var i = 0; i < forms.length; i += 1) {
    forms[i].addEventListener('submit', handleFormSubmit);
  }
}

// TOGGLING MENU //

function getMenu(el) {
  var parentDiv = el.closest('div.ellipsis-menu');
  var menu = parentDiv.querySelector('ul.ellipsis-menu');
  return menu;
}

function hideIfNotAlreadyHidden(menu) {
  if (!menu.classList.contains('hidden')) {
    menu.classList.add('hidden');
  }
}

function hideAllEllipsisMenusExcept(menu) {
  var menus = document.querySelectorAll('ul.ellipsis-menu');

  for (var i = 0; i < menus.length; i += 1) {
    if (menus[i] !== menu) {
      hideIfNotAlreadyHidden(menus[i]);
    }
  }
}

function hideEllipsisMenus(e) {
  if (!e.target.closest('div.ellipsis-menu')) {
    var menus = document.querySelectorAll('ul.ellipsis-menu');

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

  if (menu.classList.contains('hidden')) {
    menu.classList.remove('hidden');
  } else {
    menu.classList.add('hidden');
  }
}

function initializeEllipsisMenuToggle() {
  var buttons = document.getElementsByClassName('ellipsis-menu-btn');

  for (var i = 0; i < buttons.length; i += 1) {
    buttons[i].addEventListener('click', toggleEllipsisMenu);
  }

  // Hide ellipsis menus when you click outside of the ellipsis menu parent div
  const body = document.getElementsByTagName('body')[0];
  if (body) {
    body.addEventListener('click', hideEllipsisMenus);
  }
}

function initializeEllipsisMenu() {
  initializeEllipsisMenuToggle();
  initializeFormSubmit();
}
