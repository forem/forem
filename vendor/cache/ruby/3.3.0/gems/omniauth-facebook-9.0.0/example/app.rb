require 'sinatra'
require "sinatra/reloader"
require 'yaml'
require 'json'

# configure sinatra
set :run, false
set :raise_errors, true

# REQUEST STEP (server-side flow)
get '/server-side' do
  # NOTE: You would just hit this endpoint directly from the browser in a real app. The redirect is
  #       just here to explicit declare this server-side flow.
  redirect '/auth/facebook'
end

# REQUEST STEP (client-side flow)
get '/client-side' do
  content_type 'text/html'
  # NOTE: When you enable cookie below in the FB.init call the GET request in the FB.login callback
  #       will send a signed request in a cookie back the OmniAuth callback which will parse out the
  #       authorization code and obtain an access_token with it.
  <<-HTML
    <html>
    <head>
      <title>Client-side Flow Example</title>
      <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.2/jquery.min.js" type="text/javascript"></script>
      <script type="text/javascript">
        window.fbAsyncInit = function() {
          FB.init({
            appId: '#{ENV['FACEBOOK_APP_ID']}',
            version: 'v4.0',
            cookie: true // IMPORTANT must enable cookies to allow the server to access the session
          });
          console.log("fb init");
        };

        (function(d, s, id){
           var js, fjs = d.getElementsByTagName(s)[0];
           if (d.getElementById(id)) {return;}
           js = d.createElement(s); js.id = id;
           js.src = "//connect.facebook.net/en_US/sdk.js";
           fjs.parentNode.insertBefore(js, fjs);
         }(document, 'script', 'facebook-jssdk'));
      </script>
    </head>
    <body>
      <div id="fb-root"></div>

      <p id="connect">
        <a href="#">Connect to FB!</a>
      </p>

      <p id="results" />

      <script type="text/javascript">
        $('a').click(function(e) {
          e.preventDefault();

          FB.login(function(response) {
            console.log(response);
            if (response.authResponse) {
              $('#connect').html('Connected! Hitting OmniAuth callback (GET /auth/facebook/callback)...');

              // since we have cookies enabled, this request will allow omniauth to parse
              // out the auth code from the signed request in the fbsr_XXX cookie
              $.getJSON('/auth/facebook/callback', function(json) {
                $('#connect').html('Connected! Callback complete.');
                $('#results').html(JSON.stringify(json));
              });
            }
          }); // if you want custom scopes, pass them as an extra, final argument to FB.login
        });
      </script>
    </body>
    </html>
  HTML
end

# CALLBACK STEP
# - redirected here for server-side flow
# - ajax request made here for client-side flow
get '/auth/:provider/callback' do
  content_type 'application/json'
  JSON.dump(request.env)
end
