class ApplicationMailer < ActionMailer::Base
  default from: "The DEV Community <yo@dev.to>"
  layout 'mailer'
end
