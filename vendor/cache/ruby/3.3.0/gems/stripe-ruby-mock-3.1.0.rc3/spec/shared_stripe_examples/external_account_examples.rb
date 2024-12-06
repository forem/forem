require 'spec_helper'

shared_examples 'External Account API' do

  it 'creates/returns a bank when using account.external_accounts.create given a bank token' do
    account = Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")
    bank_token = stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099)
    bank = account.external_accounts.create(external_account: bank_token)

    expect(bank.account).to eq('test_account')
    expect(bank.last4).to eq("1123")
    expect(bank.exp_month).to eq(11)
    expect(bank.exp_year).to eq(2099)

    account = Stripe::Account.retrieve('test_account')
    expect(account.external_accounts.count).to eq(1)
    bank = account.external_accounts.first
    expect(bank.account).to eq('test_account')
    expect(bank.last4).to eq("1123")
    expect(bank.exp_month).to eq(11)
    expect(bank.exp_year).to eq(2099)
  end

  it 'creates/returns a bank when using account.external_accounts.create given bank params' do
    account = Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")
    bank = account.external_accounts.create(external_account: {
                                              object: 'bank_account',
                                              account_number: '000123456789',
                                              routing_number: '110000000',
                                              country: 'US',
                                              currency: 'usd'
                                            })

    expect(bank.account).to eq('test_account')
    expect(bank.routing_number).to eq('110000000')
    expect(bank.country).to eq('US')
    expect(bank.currency).to eq('usd')

    account = Stripe::Account.retrieve('test_account')
    expect(account.external_accounts.count).to eq(1)
    bank = account.external_accounts.first
    expect(bank.account).to eq('test_account')
    expect(bank.routing_number).to eq('110000000')
    expect(bank.country).to eq('US')
    expect(bank.currency).to eq('usd')
  end

  it "creates a single bank with a generated bank token" do
    account = Stripe::Account.create(type: 'custom', country: "US")
    expect(account.external_accounts.count).to eq 0

    account.external_accounts.create external_account: stripe_helper.generate_bank_token
    # Yes, stripe-ruby does not actually add the new bank to the account instance
    expect(account.external_accounts.count).to eq 0

    account2 = Stripe::Account.retrieve(account.id)
    expect(account2.external_accounts.count).to eq 1
  end

  describe "retrieval and deletion with accounts" do
    let!(:account) { Stripe::Account.create(id: 'test_account', type: 'custom', country: "US") }
    let!(:bank_token) { stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:bank) { account.external_accounts.create(external_account: bank_token) }

    it "can retrieve all account's banks" do
      retrieved = account.external_accounts.list
      expect(retrieved.count).to eq(1)
    end

    it "retrieves an account bank" do
      retrieved = account.external_accounts.retrieve(bank.id)
      expect(retrieved.to_s).to eq(bank.to_s)
    end

    it "retrieves an account's bank after re-fetching the account" do
      retrieved = Stripe::Account.retrieve(account.id).external_accounts.retrieve(bank.id)
      expect(retrieved.id).to eq bank.id
    end

    it "deletes an accounts bank" do
      bank.delete
      retrieved_acct = Stripe::Account.retrieve(account.id)
      expect(retrieved_acct.external_accounts.data).to be_empty
    end

    context "deletion when the user has two external accounts" do
      let!(:bank_token_2) { stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099) }
      let!(:bank_2) { account.external_accounts.create(external_account: bank_token_2) }

      it "has just one bank anymore" do
        bank.delete
        retrieved_acct = Stripe::Account.retrieve(account.id)
        expect(retrieved_acct.external_accounts.data.count).to eq 1
        expect(retrieved_acct.external_accounts.data.first.id).to eq bank_2.id
      end
    end
  end

  describe "Errors" do
    it "throws an error when the account does not have the retrieving bank id" do
      account = Stripe::Account.create(type: 'custom', country: "US")
      bank_id = "bank_123"
      expect { account.external_accounts.retrieve(bank_id) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.message).to match /no.*source/i
        expect(e.message).to include bank_id
        expect(e.param).to eq 'id'
        expect(e.http_status).to eq 404
      }
    end
  end

  context "update bank" do
    let!(:account) { Stripe::Account.create(id: 'test_account', type: 'custom', country: "US") }
    let!(:bank_token) { stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:bank) { account.external_accounts.create(external_account: bank_token) }

    it "updates the bank" do
      exp_month = 10
      exp_year = 2098

      bank.exp_month = exp_month
      bank.exp_year = exp_year
      bank.save

      retrieved = account.external_accounts.retrieve(bank.id)

      expect(retrieved.exp_month).to eq(exp_month)
      expect(retrieved.exp_year).to eq(exp_year)
    end
  end

  context "retrieve multiple banks" do

    it "retrieves a list of multiple banks" do
      account = Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")

      bank_token = stripe_helper.generate_bank_token(last4: "1123", exp_month: 11, exp_year: 2099)
      bank1 = account.external_accounts.create(external_accout: bank_token)
      bank_token = stripe_helper.generate_bank_token(last4: "1124", exp_month: 12, exp_year: 2098)
      bank2 = account.external_accounts.create(external_account: bank_token)

      account = Stripe::Account.retrieve('test_account')

      list = account.external_accounts.list

      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)

      expect(list.data.first.object).to eq("bank_account")
      expect(list.data.first.to_hash).to eq(bank1.to_hash)

      expect(list.data.last.object).to eq("bank_account")
      expect(list.data.last.to_hash).to eq(bank2.to_hash)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Account.create(id: 'no_banks', type: 'custom', country: "US")
      account = Stripe::Account.retrieve('no_banks')

      list = account.external_accounts.list

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

end
