##
# Custom Audit Instrumentation
#
# Put here all custom listener names, for later usage in Audit Instrumentation
#
# Example:
# Audit::Subscribe.listen :internal, :quest_user

Rails.application.reloader.to_prepare do
  Audit::Subscribe.listen(:moderator, :internal) unless Rails.env.test?
  Audit::Subscribe.listen(:admin_api, :internal) unless Rails.env.test?
end
