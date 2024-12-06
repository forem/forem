require 'spec_helper'

shared_examples 'Account Link API' do
  describe 'create account link' do
    it 'creates an account link' do
      account_link = Stripe::AccountLink.create(
        type: 'onboarding',
        account: 'acct_103ED82ePvKYlo2C',
        failure_url: 'https://stripe.com',
        success_url: 'https://stripe.com'
      )

      expect(account_link).to be_a Stripe::AccountLink
    end
  end
end
