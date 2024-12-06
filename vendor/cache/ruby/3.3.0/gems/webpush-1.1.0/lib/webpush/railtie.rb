# frozen_string_literal: true

module Webpush
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/webpush.rake'
    end
  end
end
