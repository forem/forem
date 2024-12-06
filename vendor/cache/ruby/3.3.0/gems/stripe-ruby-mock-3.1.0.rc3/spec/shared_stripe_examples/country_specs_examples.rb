require 'spec_helper'

shared_examples 'Country Spec API' do
  context 'retrieve country', live: true do
    it 'retrieves a stripe country spec' do
      country = Stripe::CountrySpec.retrieve('US')

      expect(country).to be_a Stripe::CountrySpec
      expect(country.id).to match /US/
    end

    it "cannot retrieve a stripe country that doesn't exist" do
      expect { Stripe::CountrySpec.retrieve('nope') }
          .to raise_error(Stripe::InvalidRequestError, /(nope is not currently supported by Stripe)|(Country 'nope' is unknown)/)

    end
  end
end
