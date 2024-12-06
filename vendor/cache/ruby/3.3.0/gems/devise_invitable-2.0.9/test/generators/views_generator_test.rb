require 'test_helper'
require 'fileutils'
require 'rails/generators'
require File.expand_path('../../lib/generators/devise_invitable/views_generator.rb', File.dirname(__FILE__))

class ViewsGeneratorTest < ::Rails::Generators::TestCase
  tests DeviseInvitable::Generators::ViewsGenerator
  destination File.expand_path('../../tmp', File.dirname(__FILE__))

  test 'views get copied' do
    run_generator

    assert_directory @mailer_path       = 'app/views/devise/mailer'
    assert_directory @invitations_path  = 'app/views/devise/invitations'
    assert_files
  end

  test 'views can be scoped' do
    run_generator %w(octopussies)

    assert_directory @mailer_path       = 'app/views/octopussies/mailer'
    assert_directory @invitations_path  = 'app/views/octopussies/invitations'
    assert_files
  end

  def teardown
    FileUtils.rm_r Dir['../../tmp/*']
  end

  private

    def assert_files
      assert views = { @invitations_path => %w/edit.html.erb new.html.erb/, @mailer_path => %w/invitation_instructions.html.erb/ }

      views.each do |path, files|
        files.each do |file|
          assert_file File.join path, file
        end
      end
    end
end
