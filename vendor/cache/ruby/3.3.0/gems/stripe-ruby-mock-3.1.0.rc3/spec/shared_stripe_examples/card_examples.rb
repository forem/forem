require 'spec_helper'

shared_examples 'Card API' do

  it 'creates/returns a card when using customer.sources.create given a card token' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card_token = stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.sources.create(source: card_token)

    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.sources.count).to eq(1)
    card = customer.sources.data.first
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)
  end

  it 'creates/returns a card when using recipient.cards.create given a card token', skip: 'Stripe has deprecated Recipients' do
    params = {
      id: 'test_recipient_sub',
      name: 'MyRec',
      type: 'individual'
    }

    recipient = Stripe::Recipient.create(params)
    card_token = stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = recipient.cards.create(card: card_token)

    expect(card.recipient).to eq('test_recipient_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)

    recipient = Stripe::Recipient.retrieve('test_recipient_sub')
    expect(recipient.cards.count).to eq(1)
    card = recipient.cards.data.first
    expect(card.recipient).to eq('test_recipient_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)
  end

  it 'creates/returns a card when using customer.sources.create given card params' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card = customer.sources.create(card: {
      number: '4242424242424242',
      exp_month: '11',
      exp_year: '3031',
      cvc: '123'
    })

    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("4242")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.sources.count).to eq(1)
    card = customer.sources.data.first
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("4242")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)
  end

  it 'creates/returns a card when using recipient.cards.create given card params', skip: 'Stripe has deprecated Recipients' do
    params = {
      id: 'test_recipient_sub',
      name: 'MyRec',
      type: 'individual'
    }
    recipient = Stripe::Recipient.create(params)
    card = recipient.cards.create(card: {
      number: '4000056655665556',
      exp_month: '11',
      exp_year: '3031',
      cvc: '123'
    })

    expect(card.recipient).to eq('test_recipient_sub')
    expect(card.last4).to eq("5556")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)

    recipient = Stripe::Recipient.retrieve('test_recipient_sub')
    expect(recipient.cards.count).to eq(1)
    card = recipient.cards.data.first
    expect(card.recipient).to eq('test_recipient_sub')
    expect(card.last4).to eq("5556")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)
  end

  it "creates a single card with a generated card token", :live => true do
    customer = Stripe::Customer.create
    expect(customer.sources.count).to eq 0

    customer.sources.create :source => stripe_helper.generate_card_token
    # Yes, stripe-ruby does not actually add the new card to the customer instance
    expect(customer.sources.count).to eq 0

    customer2 = Stripe::Customer.retrieve(customer.id)
    expect(customer2.sources.count).to eq 1
    expect(customer2.default_source).to eq customer2.sources.first.id
  end

  it 'create does not change the customers default card if already set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub', default_source: "test_cc_original")
    card_token = stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.sources.create(source: card_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_source).to eq("test_cc_original")
  end

  it 'create updates the customers default card if not set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card_token = stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.sources.create(source: card_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_source).to_not be_nil
  end

  describe "retrieval and deletion with customers" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:card_token) { stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:card) { customer.sources.create(source: card_token) }

    it "can retrieve all customer's cards" do
      retrieved = customer.sources.list
      expect(retrieved.count).to eq(1)
    end

    it "retrieves a customers card" do
      retrieved = customer.sources.retrieve(card.id)
      expect(retrieved.to_s).to eq(card.to_s)
    end

    it "retrieves a customer's card after re-fetching the customer" do
      retrieved = Stripe::Customer.retrieve(customer.id).sources.retrieve(card.id)
      expect(retrieved.id).to eq card.id
    end

    it "deletes a customers card" do
      card.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.sources.data).to be_empty
    end

    it "deletes a customers card then set the default_card to nil" do
      card.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.default_source).to be_nil
    end

    it "updates the default card if deleted" do
      card.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.default_source).to be_nil
    end

    it 'updates total_count if deleted' do
      card.delete
      sources = Stripe::Customer.retrieve(customer.id).sources

      expect(sources.total_count).to eq 0
    end

    context "deletion when the user has two cards" do
      let!(:card_token_2) { stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
      let!(:card_2) { customer.sources.create(source: card_token_2) }

      it "has just one card anymore" do
        card.delete
        retrieved_cus = Stripe::Customer.retrieve(customer.id)
        expect(retrieved_cus.sources.data.count).to eq 1
        expect(retrieved_cus.sources.data.first.id).to eq card_2.id
      end

      it "sets the default_card id to the last card remaining id" do
        card.delete
        retrieved_cus = Stripe::Customer.retrieve(customer.id)
        expect(retrieved_cus.default_source).to eq card_2.id
      end
    end
  end

  describe "retrieval and deletion with recipients", :live => true, skip: 'Stripe has deprecated Recipients' do
    let!(:recipient) { Stripe::Recipient.create(name: 'Test Recipient', type: 'individual') }
    let!(:card_token) { stripe_helper.generate_card_token(number: "4000056655665556") }
    let!(:card) { recipient.cards.create(card: card_token) }

    it "can retrieve all recipient's cards" do
      retrieved = recipient.cards.list
      expect(retrieved.count).to eq(1)
    end

    it "deletes a recipient card" do
      card.delete
      retrieved_cus = Stripe::Recipient.retrieve(recipient.id)
      expect(retrieved_cus.cards.data).to be_empty
    end

    it "deletes a recipient card then set the default_card to nil" do
      card.delete
      retrieved_cus = Stripe::Recipient.retrieve(recipient.id)
      expect(retrieved_cus.default_card).to be_nil
    end

    context "deletion when the recipient has two cards" do
      let!(:card_token_2) {  stripe_helper.generate_card_token(number: "5200828282828210") }
      let!(:card_2) { recipient.cards.create(card: card_token_2) }

      it "has just one card anymore" do
        card.delete
        retrieved_rec = Stripe::Recipient.retrieve(recipient.id)
        expect(retrieved_rec.cards.data.count).to eq 1
        expect(retrieved_rec.cards.data.first.id).to eq card_2.id
      end

      it "sets the default_card id to the last card remaining id" do
        card.delete
        retrieved_rec = Stripe::Recipient.retrieve(recipient.id)
        expect(retrieved_rec.default_card).to eq card_2.id
      end
    end
  end

  describe "Errors", :live => true do
    it "throws an error when the customer does not have the retrieving card id" do
      customer = Stripe::Customer.create
      card_id = "card_123"
      expect { customer.sources.retrieve(card_id) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.message).to match /no.*source/i
        expect(e.message).to include card_id
        expect(e.param).to eq 'id'
        expect(e.http_status).to eq 404
      }
    end
  end

  context "update card" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:card_token) { stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:card) { customer.sources.create(source: card_token) }

    it "updates the card" do
      exp_month = 10
      exp_year = 2098

      card.exp_month = exp_month
      card.exp_year = exp_year
      card.save

      retrieved = customer.sources.retrieve(card.id)

      expect(retrieved.exp_month).to eq(exp_month)
      expect(retrieved.exp_year).to eq(exp_year)
    end
  end

  context "retrieve multiple cards" do

    it "retrieves a list of multiple cards" do
      customer = Stripe::Customer.create(id: 'test_customer_card')

      card_token = stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
      card1 = customer.sources.create(source: card_token)
      card_token = stripe_helper.generate_card_token(last4: "1124", exp_month: 12, exp_year: 2098)
      card2 = customer.sources.create(source: card_token)

      customer = Stripe::Customer.retrieve('test_customer_card')

      list = customer.sources.list

      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)

      expect(list.data.first.object).to eq("card")
      expect(list.data.first.to_hash).to eq(card1.to_hash)

      expect(list.data.last.object).to eq("card")
      expect(list.data.last.to_hash).to eq(card2.to_hash)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Customer.create(id: 'no_cards')
      customer = Stripe::Customer.retrieve('no_cards')

      list = customer.sources.list

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

end
