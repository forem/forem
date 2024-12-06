require 'spec_helper'

shared_examples "Multiple Customer Cards" do
  it "handles multiple cards", :live => true do
    tok1 = Stripe::Token.retrieve stripe_helper.generate_card_token :number => "4242424242424242"
    tok2 = Stripe::Token.retrieve stripe_helper.generate_card_token :number => "4012888888881881"

    cus = Stripe::Customer.create(:email => 'alice@bob.com', :source => tok1.id)
    default_card = cus.sources.first
    cus.sources.create(:source => tok2.id)

    cus = Stripe::Customer.retrieve(cus.id)
    expect(cus.sources.count).to eq(2)
    expect(cus.default_source).to eq default_card.id
  end

  it "gives the same two card numbers the same fingerprints", :live => true do
    tok1 = Stripe::Token.retrieve stripe_helper.generate_card_token :number => "4242424242424242"
    tok2 = Stripe::Token.retrieve stripe_helper.generate_card_token :number => "4242424242424242"

    cus = Stripe::Customer.create(:email => 'alice@bob.com', :source => tok1.id)

    cus = Stripe::Customer.retrieve(cus.id)
    card = cus.sources.find do |existing_card|
      existing_card.fingerprint == tok2.card.fingerprint
    end
    expect(card).to_not be_nil
  end

  it "gives different card numbers different fingerprints", :live => true do
    tok1 = Stripe::Token.retrieve stripe_helper.generate_card_token :number => "4242424242424242"
    tok2 = Stripe::Token.retrieve stripe_helper.generate_card_token :number => "4012888888881881"

    cus = Stripe::Customer.create(:email => 'alice@bob.com', :source => tok1.id)

    cus = Stripe::Customer.retrieve(cus.id)
    source = cus.sources.find do |existing_card|
      existing_card.fingerprint == tok2.card.fingerprint
    end
    expect(source).to be_nil
  end
end
