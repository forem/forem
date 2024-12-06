require 'spec_helper'

shared_examples 'Balance Transaction API' do

  let(:stripe_helper) { StripeMock.create_test_helper }

  it "returns an error if balance transaction does not exist" do
    txn_id = 'txn_xxxxxxxxxxxxxxxxxxxxxxxx'

    expect {
      Stripe::BalanceTransaction.retrieve(txn_id)
    }.to raise_error { |e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such balance_transaction: ' + txn_id)
    }
  end

  it "retrieves a single balance transaction" do
    txn_id = 'txn_05RsQX2eZvKYlo2C0FRTGSSA'
    txn = Stripe::BalanceTransaction.retrieve(txn_id)

    expect(txn).to be_a(Stripe::BalanceTransaction)
    expect(txn.id).to eq(txn_id)
  end

  describe "listing balance transactions" do

    it "retrieves all balance transactions" do
      disputes = Stripe::BalanceTransaction.list

      expect(disputes.count).to eq(10)
      expect(disputes.map &:id).to include('txn_05RsQX2eZvKYlo2C0FRTGSSA','txn_15RsQX2eZvKYlo2C0ERTYUIA', 'txn_25RsQX2eZvKYlo2C0ZXCVBNM', 'txn_35RsQX2eZvKYlo2C0QAZXSWE', 'txn_45RsQX2eZvKYlo2C0EDCVFRT', 'txn_55RsQX2eZvKYlo2C0OIKLJUY', 'txn_65RsQX2eZvKYlo2C0ASDFGHJ', 'txn_75RsQX2eZvKYlo2C0EDCXSWQ', 'txn_85RsQX2eZvKYlo2C0UJMCDET', 'txn_95RsQX2eZvKYlo2C0EDFRYUI')
    end

  end

  it 'retrieves balance transactions for an automated transfer' do
    transfer_id = Stripe::Transfer.create({ amount: 2730, currency: "usd" })

    # verify transfer currently has no balance transactions
    transfer_transactions = Stripe::BalanceTransaction.list({transfer: transfer_id})
    expect(transfer_transactions.count).to eq(0)

    # verify we can create a new balance transaction associated with the transfer
    new_txn_id = stripe_helper.upsert_stripe_object(:balance_transaction, {amount: 12300, transfer: transfer_id})
    new_txn = Stripe::BalanceTransaction.retrieve(new_txn_id)
    expect(new_txn).to be_a(Stripe::BalanceTransaction)
    expect(new_txn.amount).to eq(12300)
    # although transfer was specified as an attribute on the balance_transaction, it should not be returned in the object
    expect{new_txn.transfer}.to raise_error(NoMethodError)

    # verify we can update an existing balance transaction to associate with the transfer
    existing_txn_id = 'txn_05RsQX2eZvKYlo2C0FRTGSSA'
    existing_txn = Stripe::BalanceTransaction.retrieve(existing_txn_id)
    stripe_helper.upsert_stripe_object(:balance_transaction, {id: existing_txn_id, transfer: transfer_id})

    # now verify that only these balance transactions are retrieved with the transfer
    transfer_transactions = Stripe::BalanceTransaction.list({transfer: transfer_id})
    expect(transfer_transactions.count).to eq(2)
    expect(transfer_transactions.map &:id).to include(new_txn_id, existing_txn_id)
  end

end
