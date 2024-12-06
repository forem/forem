require 'spec_helper'

shared_examples 'Bank API' do

  it 'creates/returns a bank when using customer.sources.create given a bank token' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank_token = stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099)
    bank = customer.sources.create(source: bank_token)

    expect(bank.customer).to eq('test_customer_sub')
    expect(bank.last4).to eq("1123")
    expect(bank.exp_month).to eq(11)
    expect(bank.exp_year).to eq(2099)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.sources.count).to eq(1)
    bank = customer.sources.data.first
    expect(bank.customer).to eq('test_customer_sub')
    expect(bank.last4).to eq("1123")
    expect(bank.exp_month).to eq(11)
    expect(bank.exp_year).to eq(2099)
  end

  it 'creates/returns a bank when using customer.sources.create given bank params' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank = customer.sources.create(bank: {
      number: '4242424242424242',
      exp_month: '11',
      exp_year: '3031',
      cvc: '123'
    })

    expect(bank.customer).to eq('test_customer_sub')
    expect(bank.last4).to eq("6789")

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.sources.count).to eq(1)
    bank = customer.sources.data.first
    expect(bank.customer).to eq('test_customer_sub')
    expect(bank.last4).to eq("6789")
  end

  it "creates a single bank with a generated bank token" do
    customer = Stripe::Customer.create
    expect(customer.sources.count).to eq 0

    customer.sources.create :source => stripe_helper.generate_bank_token
    # Yes, stripe-ruby does not actually add the new bank to the customer instance
    expect(customer.sources.count).to eq 0

    customer2 = Stripe::Customer.retrieve(customer.id)
    expect(customer2.sources.count).to eq 1
    expect(customer2.default_source).to eq customer2.sources.first.id
  end

  it 'create does not change the customers default bank if already set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub', default_source: "test_cc_original")
    bank_token = stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099)
    bank = customer.sources.create(source: bank_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_source).to eq("test_cc_original")
  end

  it 'create updates the customers default bank if not set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank_token = stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099)
    bank = customer.sources.create(source: bank_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_source).to_not be_nil
  end

  describe "retrieval and deletion with customers" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:bank_token) { stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:bank) { customer.sources.create(source: bank_token) }

    it "can retrieve all customer's banks" do
      retrieved = customer.sources.list
      expect(retrieved.count).to eq(1)
    end

    it "retrieves a customers bank" do
      retrieved = customer.sources.retrieve(bank.id)
      expect(retrieved.to_s).to eq(bank.to_s)
    end

    it "retrieves a customer's bank after re-fetching the customer" do
      retrieved = Stripe::Customer.retrieve(customer.id).sources.retrieve(bank.id)
      expect(retrieved.id).to eq bank.id
    end

    it "deletes a customers bank" do
      bank.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.sources.data).to be_empty
    end

    it "deletes a customers bank then set the default_bank to nil" do
      bank.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.default_source).to be_nil
    end

    it "updates the default bank if deleted" do
      bank.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.default_source).to be_nil
    end

    context "deletion when the user has two banks" do
      let!(:bank_token_2) { stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099) }
      let!(:bank_2) { customer.sources.create(source: bank_token_2) }

      it "has just one bank anymore" do
        bank.delete
        retrieved_cus = Stripe::Customer.retrieve(customer.id)
        expect(retrieved_cus.sources.data.count).to eq 1
        expect(retrieved_cus.sources.data.first.id).to eq bank_2.id
      end

      it "sets the default_bank id to the last bank remaining id" do
        bank.delete
        retrieved_cus = Stripe::Customer.retrieve(customer.id)
        expect(retrieved_cus.default_source).to eq bank_2.id
      end
    end
  end

  describe "Errors", :live => true do
    it "throws an error when the customer does not have the retrieving bank id" do
      customer = Stripe::Customer.create
      bank_id = "bank_123"
      expect { customer.sources.retrieve(bank_id) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.message).to match /no.*source/i
        expect(e.message).to include bank_id
        expect(e.param).to eq 'id'
        expect(e.http_status).to eq 404
      }
    end
  end

  context "update bank" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:bank_token) { stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:bank) { customer.sources.create(source: bank_token) }

    it "updates the bank" do
      exp_month = 10
      exp_year = 2098

      bank.exp_month = exp_month
      bank.exp_year = exp_year
      bank.save

      retrieved = customer.sources.retrieve(bank.id)

      expect(retrieved.exp_month).to eq(exp_month)
      expect(retrieved.exp_year).to eq(exp_year)
    end
  end

  context "retrieve multiple banks" do

    it "retrieves a list of multiple banks" do
      customer = Stripe::Customer.create(id: 'test_customer_bank')

      bank_token = stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099)
      bank1 = customer.sources.create(source: bank_token)
      bank_token = stripe_helper.generate_bank_token(last4: "1124", exp_month: 12, exp_year: 2098)
      bank2 = customer.sources.create(source: bank_token)

      customer = Stripe::Customer.retrieve('test_customer_bank')

      list = customer.sources.list

      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)

      expect(list.data.first.object).to eq("bank_account")
      expect(list.data.first.to_hash).to eq(bank1.to_hash)

      expect(list.data.last.object).to eq("bank_account")
      expect(list.data.last.to_hash).to eq(bank2.to_hash)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Customer.create(id: 'no_banks')
      customer = Stripe::Customer.retrieve('no_banks')

      list = customer.sources.list

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

  describe 'Stripe::Token creation from bank account' do
    it 'generates token from bank account informations' do
      token = Stripe::Token.create({
        bank_account: {
          account_number: "4222222222222222",
          routing_number: "123456",
          bank_name: "Fake bank"
        }
      })

      cus = Stripe::Customer.create(source: token.id)
      bank_account = cus.sources.data.first
      expect(bank_account.bank_name).to eq('Fake bank')
    end

    it 'generates token from existing bank account token' do
      bank_token = StripeMock.generate_bank_token(bank_name: 'Fake bank')
      cus = Stripe::Customer.create(source: bank_token)
      token = Stripe::Token.create({ customer: cus.id, bank_account: cus.sources.first.id })
      cus.sources.create(source: token.id)
      cus = Stripe::Customer.retrieve(cus.id)
      expect(cus.sources.data.count).to eq 2
      cus.sources.data.each do |source|
        expect(source.bank_name).to eq('Fake bank')
      end
    end
  end
end
