module RSpec::Rails
  RSpec.describe MailerExampleGroup do
    module ::Rails; end
    before do
      allow(Rails).to receive_message_chain(:application, :routes, :url_helpers).and_return(Rails)
      allow(Rails.application).to receive(:config).and_return(double("Rails.application.config").as_null_object)
      allow(Rails).to receive_message_chain(:configuration, :action_mailer, :default_url_options).and_return({})
    end

    it_behaves_like "an rspec-rails example group mixin", :mailer,
                    './spec/mailers/', '.\\spec\\mailers\\'
  end
end
