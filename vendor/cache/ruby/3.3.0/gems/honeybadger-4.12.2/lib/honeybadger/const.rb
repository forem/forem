require 'honeybadger/version'

module Honeybadger
  module Rack
    # Autoloading allows middleware classes to be referenced in applications
    # which include the optional Rack dependency without explicitly requiring
    # these files.
    autoload :ErrorNotifier, 'honeybadger/rack/error_notifier'
    autoload :UserFeedback, 'honeybadger/rack/user_feedback'
    autoload :UserInformer, 'honeybadger/rack/user_informer'
  end

  # @api private
  module Plugins
  end

  # @api private
  module Util
  end
end
