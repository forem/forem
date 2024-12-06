require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*'
    resource '/public', credentials: true
  end
end
