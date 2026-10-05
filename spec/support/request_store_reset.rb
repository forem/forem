RSpec.configure do |config|
  config.before do
    RequestStore.store[:subforem_id] = nil
    RequestStore.store[:default_subforem_id] = nil
    RequestStore.store[:root_subforem_id] = nil
    RequestStore.delete(Settings::Base::DEFAULT_SUBFOREM_FALLBACK_FLAG)
    RequestStore.delete(Settings::Base::DEFAULT_SUBFOREM_FALLBACK_ID)
  end
end
