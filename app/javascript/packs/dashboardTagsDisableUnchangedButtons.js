document.getElementById('follows_update_form').addEventListener('submit', checkChanged);

document.addEventListener('change', function(event) {
  if (event.target && event.target.name == 'follows[][explicit_points]'){
    addChanged(event.target)
  }
});

function addChanged(element) {
  element.setAttribute('changed', true);
};

function checkChanged(event) {
  if (document.querySelector('input[changed]')) {
    disableAllUnchanged();
  }
  else {
    event.preventDefault();
  }
};

function disableAllUnchanged() {
  document.querySelectorAll('div[id^="follows"]').forEach(disableUnchanged)
};

function disableUnchanged(item) {
  let inputs = item.getElementsByTagName('input')
  let id = inputs[0]
  let point = inputs[1]

  if (!point.hasAttribute('changed')) {
    point.setAttribute('disabled', true)
    id.setAttribute('disabled', true)
  }
};
