RSpec.configure do |config|
  config.before do
    RequestStore.store[:subforem_id] = nil
    RequestStore.store[:default_subforem_id] = nil
    RequestStore.store[:root_subforem_id] = nil
    RequestStore.store[:user_signed_in] = nil
    RequestStore.store[:custom_domain_org] = nil
  end
end
