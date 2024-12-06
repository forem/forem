require 'generators_helper'

# Generators are not automatically loaded by Rails
require 'generators/rolify/rolify_generator'

describe Rolify::Generators::RolifyGenerator, :if => ENV['ADAPTER'] == 'mongoid' do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../tmp", __FILE__)
  teardown :cleanup_destination_root

  before {
    prepare_destination
  }

  def cleanup_destination_root
    FileUtils.rm_rf destination_root
  end

  describe 'specifying ORM adapter' do
    before(:all) { arguments [ "Role", "User", "--orm=mongoid" ] }

    before {
      capture(:stdout) {
        generator.create_file "app/models/user.rb" do
<<-RUBY
class User
  include Mongoid::Document

  field :login, :type => String
end
RUBY
        end
      }
      require File.join(destination_root, "app/models/user.rb")
      run_generator
    }

    describe 'config/initializers/rolify.rb' do
      subject { file('config/initializers/rolify.rb') }
      it { should exist }
      it { should contain "Rolify.configure do |config|"}
      it { should_not contain "# config.use_mongoid" }
      it { should contain "# config.use_dynamic_shortcuts" }
    end

    describe 'app/models/role.rb' do
      subject { file('app/models/role.rb') }
      it { should exist }
      it { should contain "class Role\n" }
      it { should contain "has_and_belongs_to_many :users\n" }
      it { should contain "belongs_to :resource, :polymorphic => true" }
      it { should contain "field :name, :type => String" }
      it { should contain "  index({\n"
                          "      { :name => 1 },\n"
                          "      { :resource_type => 1 },\n"
                          "      { :resource_id => 1 }\n"
                          "    },\n"
                          "    { unique => true })"}
      it { should contain "validates :resource_type,\n"
                          "          :inclusion => { :in => Rolify.resource_types },\n"
                          "          :allow_nil => true" }
    end

    describe 'app/models/user.rb' do
      subject { file('app/models/user.rb') }
      it { should contain /class User\n  include Mongoid::Document\n  rolify\n/ }
    end
  end

  describe 'specifying namespaced User and Role class names and ORM adapter' do
    before(:all) { arguments %w(Admin::Role Admin::User --orm=mongoid) }

    before {
      capture(:stdout) {
        generator.create_file "app/models/admin/user.rb" do
<<-RUBY
module Admin
  class User
    include Mongoid::Document
  end
end
RUBY
        end
      }
      require File.join(destination_root, "app/models/admin/user.rb")
      run_generator
    }

    describe 'config/initializers/rolify.rb' do
      subject { file('config/initializers/rolify.rb') }

      it { should exist }
      it { should contain "Rolify.configure(\"Admin::Role\") do |config|"}
      it { should contain "# config.use_dynamic_shortcuts" }
      it { should_not contain "# config.use_mongoid" }
    end

    describe 'app/models/admin/role.rb' do
      subject { file('app/models/admin/role.rb') }

      it { should exist }
      it { should contain "class Admin::Role" }
      it { should contain "has_and_belongs_to_many :admin_users" }
      it { should contain "belongs_to :resource, :polymorphic => true" }
    end

    describe 'app/models/admin/user.rb' do
      subject { file('app/models/admin/user.rb') }

      it { should contain /class User\n    include Mongoid::Document\n  rolify :role_cname => 'Admin::Role'\n/ }
    end
  end
end
