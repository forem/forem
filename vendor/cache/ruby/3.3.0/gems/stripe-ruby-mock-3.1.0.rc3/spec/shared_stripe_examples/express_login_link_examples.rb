require 'spec_helper'

shared_examples 'Express Login Link API' do
  describe 'create an Express Login Link' do
    it 'creates a login link' do
      account_link = Stripe::Account.create_login_link('acct_103ED82ePvKYlo2C')

      expect(account_link).to be_a Stripe::LoginLink
      expect(account_link.url).to start_with('https://connect.stripe.com/express/')
    end
  end
end
