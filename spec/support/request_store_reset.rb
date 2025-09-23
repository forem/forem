RSpec.configure do |config|
  config.before do
    RequestStore.store[:subforem_id] = nil
    RequestStore.store[:default_subforem_id] = nil
    RequestStore.store[:root_subforem_id] = nil
  end
end
