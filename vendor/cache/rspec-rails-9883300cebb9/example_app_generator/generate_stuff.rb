require 'rspec/rails/feature_check'

DEFAULT_SOURCE_PATH = File.expand_path(__dir__)

module ExampleAppHooks
  module AR
    def source_paths
      @__source_paths__ ||= [DEFAULT_SOURCE_PATH]
    end

    def setup_tasks
      # no-op
    end

    def final_tasks
      copy_file 'spec/verify_active_record_spec.rb'
      copy_file 'app/views/foo.html'
      copy_file 'app/views/some_templates/bar.html'
      copy_file 'spec/verify_custom_renderers_spec.rb'
      copy_file 'spec/verify_fixture_warning_spec.rb'
      run('bin/rake db:migrate')
    end

    def skip_active_record?
      false
    end
  end

  module NoAR
    def source_paths
      @__source_paths__ ||= [File.join(DEFAULT_SOURCE_PATH, 'no_active_record')]
    end

    def setup_tasks
      copy_file 'app/models/in_memory/model.rb'
      copy_file 'lib/rails/generators/in_memory/model/model_generator.rb'
      copy_file 'lib/rails/generators/in_memory/model/templates/model.rb.erb'
      application <<-CONFIG
        config.generators do |g|
          g.orm :in_memory, :migration => false
        end
      CONFIG
    end

    def final_tasks
      copy_file 'spec/verify_no_active_record_spec.rb'
      copy_file 'spec/verify_no_fixture_setup_spec.rb'
      copy_file 'spec/verify_fixture_file_upload_spec.rb'
    end

    def skip_active_record?
      true
    end
  end

  def self.environment_hooks
    if defined?(ActiveRecord)
      AR
    else
      NoAR
    end
  end
end

def generate(*)
  super
  $?.success? || abort
end

def using_source_path(path)
  source_paths.unshift path
  yield
ensure
  # Remove our path munging
  source_paths.shift
end

# Generally polluting `main` is bad as it monkey patches all objects. In this
# context, `self` is an _instance_ of a `Rails::Generators::AppGenerator`. So
# this won't pollute anything.
extend ExampleAppHooks.environment_hooks

setup_tasks

generate('rspec:install')
generate('controller wombats index') # plural
generate('controller welcome index') # singular

# request specs are now the default
generate('rspec:controller wombats --no-request-specs --controller-specs --no-view-specs')

generate('integration_test widgets')
generate('mailer Notifications signup')

generate('model thing name:string')
generate('helper things')
generate('scaffold widget name:string category:string instock:boolean foo_id:integer bar_id:integer --force')
generate('scaffold gadget') # scaffold with no attributes
generate('scaffold ticket original_price:float discounted_price:float')
generate('scaffold admin/account name:string') # scaffold with nested resource
generate('scaffold card --api')
generate('scaffold upload --no-request_specs --controller_specs')
generate('rspec:feature gadget')
generate('controller things custom_action')

using_source_path(File.expand_path(__dir__)) do
  # rspec-core loads files alphabetically, so we want this to be the first one
  copy_file 'spec/features/model_mocks_integration_spec.rb'
end

begin
  require 'action_mailbox'
  run('rails action_mailbox:install')
rescue LoadError
end

begin
  require 'active_job'
  generate('job upload_backups')
rescue LoadError
end

begin
  require 'action_cable'
  require 'action_cable/test_helper'
  generate('channel chat')
rescue LoadError
end

file "app/views/things/custom_action.html.erb",
     "This is a template for a custom action.",
     force: true

file "app/views/errors/401.html.erb",
     "This is a template for rendering an error page",
     force: true

# Use the absolute path so we can load it without active record too
apply File.join(DEFAULT_SOURCE_PATH, 'generate_action_mailer_specs.rb')
using_source_path(File.expand_path(__dir__)) do
  # rspec-core loads files alphabetically, so we want this to be the first one
  copy_file 'spec/__verify_fixture_load_order_spec.rb'
end

gsub_file 'spec/spec_helper.rb', /^=(begin|end)/, ''

# Warnings are too noisy in the sample apps
gsub_file 'spec/spec_helper.rb',
          'config.warnings = true',
          'config.warnings = false'
gsub_file '.rspec', '--warnings', ''

# Make a generated file work
gsub_file 'app/views/cards/_card.json.jbuilder',
          ', :created_at, :updated_at',
          ''

# Remove skips so we can test specs work
gsub_file 'spec/requests/cards_spec.rb',
          'skip("Add a hash of attributes valid for your model")',
          '{}'

gsub_file 'spec/requests/gadgets_spec.rb',
          'skip("Add a hash of attributes valid for your model")',
          '{}'

gsub_file 'spec/controllers/uploads_controller_spec.rb',
          'skip("Add a hash of attributes valid for your model")',
          '{}'
final_tasks
