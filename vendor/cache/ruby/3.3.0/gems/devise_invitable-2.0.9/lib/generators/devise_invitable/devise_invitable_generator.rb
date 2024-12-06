module DeviseInvitable
  module Generators
    class DeviseInvitableGenerator < Rails::Generators::NamedBase
      namespace 'devise_invitable'

      desc 'Add :invitable directive in the given model. Also generate migration for ActiveRecord'

      def inject_devise_invitable_content
        path = File.join('app', 'models', "#{file_path}.rb")
        inject_into_file(path, 'invitable, :', after: 'devise :') if File.exist?(path)
      end

      hook_for :orm
    end
  end
end