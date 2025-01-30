/* global checkUserLoggedIn */

function removeExistingCSRF() {
  var csrfTokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfParamMeta = document.querySelector("meta[name='csrf-param']");
  if (csrfTokenMeta && csrfParamMeta) {
    csrfTokenMeta.parentNode.removeChild(csrfTokenMeta);
    csrfParamMeta.parentNode.removeChild(csrfParamMeta);
  }
}

function fetchBaseData() {
  fetch('/async_info/base_data')
    .then((response) => response.json())
    .then(
      ({
        token,
        param,
        broadcast,
        user,
        creator,
        client_geolocation,
        default_email_optin_allowed,
      }) => {
        if (token) {
          removeExistingCSRF();
        }

        const newCsrfParamMeta = document.createElement('meta');
        newCsrfParamMeta.name = 'csrf-param';
        newCsrfParamMeta.content = param;
        document.head.appendChild(newCsrfParamMeta);

        const newCsrfTokenMeta = document.createElement('meta');
        newCsrfTokenMeta.name = 'csrf-token';
        newCsrfTokenMeta.content = token;
        document.head.appendChild(newCsrfTokenMeta);
        document.body.dataset.loaded = 'true';

        if (broadcast) {
          document.body.dataset.broadcast = broadcast;
        }

        if (checkUserLoggedIn() && user) {
          document.body.dataset.user = user;
          document.body.dataset.creator = creator;
          document.body.dataset.clientGeolocation =
            JSON.stringify(client_geolocation);
          document.body.dataset.default_email_optin_allowed =
            default_email_optin_allowed;
          const userJson = JSON.parse(user);
          browserStoreCache('set', user);
          document.body.className = userJson.config_body_class;

          if (userJson.config_body_class && userJson.config_body_class.includes('dark-theme') && document.getElementById('dark-mode-style')) {
            document.getElementById('body-styles').innerHTML = '<style>'+document.getElementById('dark-mode-style').innerHTML+'</style>'
          } else {
            document.getElementById('body-styles').innerHTML = '<style>'+document.getElementById('light-mode-style').innerHTML+'</style>'
          }
    

          setTimeout(() => {
            if (typeof ga === 'function') {
              ga('set', 'userId', userJson.id);
            }
            if (typeof gtag === 'function') {
              gtag('set', 'user_Id', userJson.id);
            }
          }, 400);
        } else if (checkUserLoggedIn()){
          // Reload page if user is present but document user check is not
          delete document.body.dataset.user;
          delete document.body.dataset.creator;
          browserStoreCache('remove');
          location.reload();
        } else {
          // Ensure user data is not exposed if no one is logged in
          delete document.body.dataset.user;
          delete document.body.dataset.creator;
          browserStoreCache('remove');
        }
      },
    );
}

function initializeBodyData() {
  fetchBaseData();
}
