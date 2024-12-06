$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
require 'test_helper'
require 'rails/generators'
require 'generators/devise_invitable/devise_invitable_generator'

class GeneratorsTest < ActiveSupport::TestCase
  RAILS_APP_PATH = File.expand_path("../rails_app", __FILE__)

  test "rails g should include the 6 generators" do
    @output     = `cd #{RAILS_APP_PATH} && rails g`
    generators  = %w/devise_invitable devise_invitable:form_for devise_invitable:install devise_invitable:invitation_views devise_invitable:simple_form_for devise_invitable:views/

    generators.each do |generator|
      @output.include? generator
    end
  end

  test "rails g devise_invitable:install" do
    @output = `cd #{RAILS_APP_PATH} && rails g devise_invitable:install -p`
    puts @output
    assert @output.match(%r{(inject|insert|File unchanged! The supplied flag value not found!).*  config/initializers/devise\.rb\n})
    assert @output.match(%r|create.*  config/locales/devise_invitable\.en\.yml\n|)
  end

  test "rails g devise_invitable Octopussy" do
    @output = `cd #{RAILS_APP_PATH} && rails g devise_invitable Octopussy -p`
    assert @output.match(%r{(inject|insert|File unchanged! The supplied flag value not found!).*  app/models/octopussy\.rb\n})
    assert @output.match(%r|invoke.*  #{DEVISE_ORM}\n|)
    if DEVISE_ORM == :active_record
      assert @output.match(%r|create.*  db/migrate/\d{14}_devise_invitable_add_to_octopussies\.rb\n|)
    elsif DEVISE_ORM == :mongoid
      assert !@output.match(%r|create.*  db/migrate/\d{14}_devise_invitable_add_to_octopussies\.rb\n|)
    end
  end
end
