# module Devise
#   module Test
#     module IntegrationHelpers
#       def sign_in(resource, scope: nil)
#         success = false
#         tries = 0
#         until success || tries == 3
#           tries += 1
#           scope ||= Devise::Mapping.find_scope!(resource)
#           login_as(resource, scope: scope)
#           binding.pry
#           # try get :index
#           # https://github.com/heartcombo/devise/wiki/How-To:-Stub-authentication-in-controller-specs
#           # https://github.com/heartcombo/devise/issues/3913#issuecomment-174737364
#         end
#       end
#     end
#   end
# end
# module Devise
#   module Test
#     module IntegrationHelpers
#       def sign_in(resource, scope: nil)
#         scope ||= Devise::Mapping.find_scope!(resource)
#         result = login_as(resource, scope: scope)
#         Warden::Manager.on_request do |proxy|
#           Rails.logger.error("in warden manager")
#           result.first.call(proxy)
#         end
#       end
#     end
#   end
# end

Warden::Manager.before_failure do |env, opts|
  Rails.logger.error("env: #{env} \nopts: #{opts}")
end
