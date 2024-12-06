# frozen_string_literal: true

require "better_html/better_erb"

module BetterHtml
  class Railtie < Rails::Railtie
    initializer "better_html.better_erb.initialization" do
      BetterHtml::BetterErb.prepend!
    end
  end
end
