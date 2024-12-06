require 'generators_helper'

# Generators are not automatically loaded by Rails
require 'generators/rolify/rolify_generator'

describe Rolify::Generators::RolifyGenerator, :if => ENV['ADAPTER'] == 'active_record' do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../tmp", __FILE__)
  teardown :cleanup_destination_root

  let(:adapter) { 'SQLite3Adapter' }
  before {
    prepare_destination
  }

  def cleanup_destination_root
    FileUtils.rm_rf destination_root
  end

  describe 'specifying only Role class name' do
    before(:all) { arguments %w(Role) }

    before {
      allow(ActiveRecord::Base).to receive_message_chain(
        'connection.class.to_s.demodulize') { adapter }
      capture(:stdout) {
        generator.create_file "app/models/user.rb" do
          <<-RUBY
          class User < ActiveRecord::Base
          end
          RUBY
        end
      }
      require File.join(destination_root, "app/models/user.rb")
      if Rails::VERSION::MAJOR >= 7
        run_generator %w(--skip-collision-check)
      else
        run_generator
      end
    }

    describe 'config/initializers/rolify.rb' do
      subject { file('config/initializers/rolify.rb') }
      it { should exist }
      it { should contain "Rolify.configure do |config|"}
      it { should contain "# config.use_dynamic_shortcuts" }
      it { should contain "# config.use_mongoid" }
    end

    describe 'app/models/role.rb' do
      subject { file('app/models/role.rb') }
      it { should exist }
      it do
        if Rails::VERSION::MAJOR < 5
          should contain "class Role < ActiveRecord::Base"
        else
          should contain "class Role < ApplicationRecord"
        end
      end
      it { should contain "has_and_belongs_to_many :users, :join_table => :users_roles" }
      it do
        if Rails::VERSION::MAJOR < 5
          should contain "belongs_to :resource,\n"
                          "           :polymorphic => true"
        else
          should contain "belongs_to :resource,\n"
                          "           :polymorphic => true,\n"
                          "           :optional => true"
        end
      end
      it { should contain "belongs_to :resource,\n"
                          "           :polymorphic => true,\n"
                          "           :optional => true"
      }
      it { should contain "validates :resource_type,\n"
                          "          :inclusion => { :in => Rolify.resource_types },\n"
                          "          :allow_nil => true" }
      it { should contain "scopify" }
    end

    describe 'app/models/user.rb' do
      subject { file('app/models/user.rb') }
      it { should contain /class User < ActiveRecord::Base\n  rolify\n/ }
    end

    describe 'migration file' do
      subject { migration_file('db/migrate/rolify_create_roles.rb') }

      it { should be_a_migration }
      it { should contain "create_table(:roles) do" }
      it { should contain "create_table(:users_roles, :id => false) do" }

      context 'mysql2' do
        let(:adapter) { 'Mysql2Adapter' }

        it { expect(subject).to contain('add_index(:roles, :name)') }
      end

      context 'sqlite3' do
        let(:adapter) { 'SQLite3Adapter' }

        it { expect(subject).to contain('add_index(:roles, :name)') }
      end

      context 'pg' do
        let(:adapter) { 'PostgreSQLAdapter' }

        it { expect(subject).not_to contain('add_index(:roles, :name)') }
      end
    end
  end

  describe 'specifying User and Role class names' do
    before(:all) { arguments %w(AdminRole AdminUser) }

    before {
      allow(ActiveRecord::Base).to receive_message_chain(
        'connection.class.to_s.demodulize') { adapter }
      capture(:stdout) {
        generator.create_file "app/models/admin_user.rb" do
          "class AdminUser < ActiveRecord::Base\nend"
        end
      }
      require File.join(destination_root, "app/models/admin_user.rb")
      run_generator
    }

    describe 'config/initializers/rolify.rb' do
      subject { file('config/initializers/rolify.rb') }

      it { should exist }
      it { should contain "Rolify.configure(\"AdminRole\") do |config|"}
      it { should contain "# config.use_dynamic_shortcuts" }
      it { should contain "# config.use_mongoid" }
    end

    describe 'app/models/admin_role.rb' do
      subject { file('app/models/admin_role.rb') }

      it { should exist }
      it do
        if Rails::VERSION::MAJOR < 5
          should contain "class AdminRole < ActiveRecord::Base"
        else
          should contain "class AdminRole < ApplicationRecord"
        end
      end
      it { should contain "has_and_belongs_to_many :admin_users, :join_table => :admin_users_admin_roles" }
      it { should contain "belongs_to :resource,\n"
                          "           :polymorphic => true,\n"
                          "           :optional => true"
      }
    end

    describe 'app/models/admin_user.rb' do
      subject { file('app/models/admin_user.rb') }

      it { should contain /class AdminUser < ActiveRecord::Base\n  rolify :role_cname => 'AdminRole'\n/ }
    end

    describe 'migration file' do
      subject { migration_file('db/migrate/rolify_create_admin_roles.rb') }

      it { should be_a_migration }
      it { should contain "create_table(:admin_roles)" }
      it { should contain "create_table(:admin_users_admin_roles, :id => false) do" }

      context 'mysql2' do
        let(:adapter) { 'Mysql2Adapter' }

        it { expect(subject).to contain('add_index(:admin_roles, :name)') }
      end

      context 'sqlite3' do
        let(:adapter) { 'SQLite3Adapter' }

        it { expect(subject).to contain('add_index(:admin_roles, :name)') }
      end

      context 'pg' do
        let(:adapter) { 'PostgreSQLAdapter' }

        it { expect(subject).not_to contain('add_index(:admin_roles, :name)') }
      end
    end
  end

  describe 'specifying namespaced User and Role class names' do
    before(:all) { arguments %w(Admin::Role Admin::User) }

    before {
      allow(ActiveRecord::Base).to receive_message_chain(
        'connection.class.to_s.demodulize') { adapter }
      capture(:stdout) {
        generator.create_file "app/models/admin/user.rb" do
          <<-RUBY
          module Admin
            class User < ActiveRecord::Base
              self.table_name_prefix = 'admin_'
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
      it { should contain "# config.use_mongoid" }
    end

    describe 'app/models/admin/role.rb' do
      subject { file('app/models/admin/role.rb') }

      it { should exist }
      it do
        if Rails::VERSION::MAJOR < 5
          should contain "class Admin::Role < ActiveRecord::Base"
        else
          should contain "class Admin::Role < ApplicationRecord"
        end
      end
      it { should contain "has_and_belongs_to_many :admin_users, :join_table => :admin_users_admin_roles" }
      it { should contain "belongs_to :resource,\n"
                          "           :polymorphic => true,\n"
                          "           :optional => true"
      }
    end

    describe 'app/models/admin/user.rb' do
      subject { file('app/models/admin/user.rb') }

      it { should contain /class User < ActiveRecord::Base\n  rolify :role_cname => 'Admin::Role'\n/ }
    end

    describe 'migration file' do
      subject { migration_file('db/migrate/rolify_create_admin_roles.rb') }

      it { should be_a_migration }
      it { should contain "create_table(:admin_roles)" }
      it { should contain "create_table(:admin_users_admin_roles, :id => false) do" }
      it do
        if Rails::VERSION::MAJOR < 5
          should contain "< ActiveRecord::Migration"
        else
          should contain "< ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end

      context 'mysql2' do
        let(:adapter) { 'Mysql2Adapter' }

        it { expect(subject).to contain('add_index(:admin_roles, :name)') }
      end

      context 'sqlite3' do
        let(:adapter) { 'SQLite3Adapter' }

        it { expect(subject).to contain('add_index(:admin_roles, :name)') }
      end

      context 'pg' do
        let(:adapter) { 'PostgreSQLAdapter' }

        it { expect(subject).not_to contain('add_index(:admin_roles, :name)') }
      end
    end
  end
end
