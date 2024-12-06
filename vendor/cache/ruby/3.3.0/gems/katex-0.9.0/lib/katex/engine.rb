# frozen_string_literal: true

module Katex
  # Registers KaTeX fonts, stylesheets, and javascripts with Rails.
  class Engine < ::Rails::Engine
    initializer 'katex.assets' do |app|
      # We deliberately do not place the assets in vendor/assets but in
      # vendor/katex instead, as vendor/assets is added to asset paths
      # by default but we have to avoid including the non-sprockets stylesheet.
      %w[fonts javascripts images].each do |sub|
        path = root.join('vendor', 'katex', sub).to_s
        app.config.assets.paths << path if File.directory?(path)
      end
      # Use sprockets versions of katex CSS that use asset-path for
      # referencing fonts.
      # One file is a Sass partial and the other one is .css.erb.
      app.config.assets.paths << root.join(
        'vendor', 'katex', 'sprockets', 'stylesheets'
      ).to_s
    end
  end
end
