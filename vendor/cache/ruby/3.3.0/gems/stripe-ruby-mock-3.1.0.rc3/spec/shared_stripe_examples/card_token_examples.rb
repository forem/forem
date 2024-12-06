require 'spec_helper'

shared_examples 'Card Token Mocking' do

  describe 'Direct Token Creation' do

    it "generates and reads a card token with default values" do
      card_token = StripeMock.generate_card_token

      charge = Stripe::Charge.create(amount: 500, currency: 'usd', source: card_token)
      card = charge.source
      expect(card.last4).to eq("4242")
      expect(card.exp_month).to eq(4)
      expect(card.exp_year).to eq(2016)
      expect(card.tokenization_method).to eq(nil)
    end

    it "generates and reads a card token for create charge" do
      card_token = StripeMock.generate_card_token(last4: "2244", exp_month: 33, exp_year: 2255)

      charge = Stripe::Charge.create(amount: 500, currency: 'usd', source: card_token)
      card = charge.source
      expect(card.last4).to eq("2244")
      expect(card.exp_month).to eq(33)
      expect(card.exp_year).to eq(2255)
    end

    it "generates and reads a card token for create customer" do
      card_token = StripeMock.generate_card_token(last4: "9191", exp_month: 99, exp_year: 3005)

      cus = Stripe::Customer.create(source: card_token)
      card = cus.sources.data.first
      expect(card.last4).to eq("9191")
      expect(card.exp_month).to eq(99)
      expect(card.exp_year).to eq(3005)
    end

    it "generates and reads a card token for update customer" do
      card_token = StripeMock.generate_card_token(last4: "1133", exp_month: 11, exp_year: 2099)

      cus = Stripe::Customer.create
      cus.source = card_token
      cus.save

      card = cus.sources.data.first
      expect(card.last4).to eq("1133")
      expect(card.exp_month).to eq(11)
      expect(card.exp_year).to eq(2099)
    end

    it "retrieves a created token" do
      card_token = StripeMock.generate_card_token(last4: "2323", exp_month: 33, exp_year: 2222)
      token = Stripe::Token.retrieve(card_token)

      expect(token.id).to eq(card_token)
      expect(token.card.last4).to eq("2323")
      expect(token.card.exp_month).to eq(33)
      expect(token.card.exp_year).to eq(2222)
    end
  end

  describe 'Stripe::Token' do

    it "generates and reads a card token for create customer" do

      card_token = Stripe::Token.create({
        card: {
          number: "4222222222222222",
          exp_month: 9,
          exp_year: 2017
        }
      })

      cus = Stripe::Customer.create(source: card_token.id)
      card = cus.sources.data.first
      expect(card.last4).to eq("2222")
      expect(card.exp_month).to eq(9)
      expect(card.exp_year).to eq(2017)
    end

    it "generates and reads a card token for update customer" do
      card_token = Stripe::Token.create({
        card: {
          number: "1111222233334444",
          exp_month: 11,
          exp_year: 2019
        }
      })

      cus = Stripe::Customer.create
      cus.source = card_token.id
      cus.save

      card = cus.sources.data.first
      expect(card.last4).to eq("4444")
      expect(card.exp_month).to eq(11)
      expect(card.exp_year).to eq(2019)
    end

    it "generates a card token created from customer" do
      card_token = Stripe::Token.create({
        card: {
          number: "1111222233334444",
          exp_month: 11,
          exp_year: 2019
        }
      })

      cus = Stripe::Customer.create()
      cus.source = card_token.id
      cus.save

      card_token = Stripe::Token.create({
        customer: cus.id
      })

      expect(card_token.object).to eq("token")
    end

    it "generates a card token from another card" do
      token = StripeMock.generate_card_token(last4: "2244", exp_month: 33, exp_year: 2255)

      cus1 = Stripe::Customer.create()
      cus1.source = token
      cus1.save

      card1 = cus1.sources.data.first
      expect(card1.last4).to eq("2244")
      expect(card1.exp_month).to eq(33)
      expect(card1.exp_year).to eq(2255)

      card_token = Stripe::Token.create({
        customer: cus1.id,
        card: card1.id
      })

      cus2 = Stripe::Customer.create()
      cus2.source = card_token.id
      cus2.save

      card2 = cus2.sources.data.first
      expect(card2.last4).to eq("2244")
      expect(card2.exp_month).to eq(33)
      expect(card2.exp_year).to eq(2255)
    end

    it 'generates a card token from another card', oauth: true do
      token = StripeMock.generate_card_token(last4: "2244", exp_month: 33, exp_year: 2255)

      cus1 = Stripe::Customer.create()
      cus1.source = token
      cus1.save

      card1 = cus1.sources.data.first
      expect(card1.last4).to eq("2244")
      expect(card1.exp_month).to eq(33)
      expect(card1.exp_year).to eq(2255)

      card_token = Stripe::Token.create({
        customer: cus1.id,
        card: card1.id
      })

      cus2 = Stripe::Customer.create({}, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])
      cus2.source = card_token.id
      cus2.save

      card2 = cus2.sources.data.first
      expect(card2.last4).to eq("2244")
      expect(card2.exp_month).to eq(33)
      expect(card2.exp_year).to eq(2255)
    end

    it "throws an error if neither card nor customer are provided", :live => true do
      expect { Stripe::Token.create }.to raise_error(
        Stripe::InvalidRequestError, /must supply either a card, customer/
      )
    end
  end

end
