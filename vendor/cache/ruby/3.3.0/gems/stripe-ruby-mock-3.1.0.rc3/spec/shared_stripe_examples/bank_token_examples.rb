require 'spec_helper'

shared_examples 'Bank Account Token Mocking' do

  it "generates a bank token with default values" do
    bank_token = StripeMock.generate_bank_token
    tokens = test_data_source(:bank_tokens)
    expect(tokens[bank_token]).to_not be_nil
    expect(tokens[bank_token][:bank_name]).to eq("STRIPEMOCK TEST BANK")
    expect(tokens[bank_token][:last4]).to eq("6789")
  end

  it "generates a bank token with an associated account in memory" do
    bank_token = StripeMock.generate_bank_token(
      :bank_name => "Memory Bank",
      :last4 => "7171"
    )
    tokens = test_data_source(:bank_tokens)
    expect(tokens[bank_token]).to_not be_nil
    expect(tokens[bank_token][:bank_name]).to eq("Memory Bank")
    expect(tokens[bank_token][:last4]).to eq("7171")
  end

  it "creates a token whose id begins with test_btok" do
    bank_token = StripeMock.generate_bank_token({
      :last4 => "1212"
    })
    expect(bank_token).to match /^test_btok/
  end

  it "assigns the generated bank account to a new recipient" do
    bank_token = StripeMock.generate_bank_token(
      :bank_name => "Bank Token Mocking",
      :last4 => "7777"
    )

    recipient = Stripe::Recipient.create({
      name: "Fred Flinstone",
      type: "individual",
      email: 'blah@domain.co',
      bank_account: bank_token
    })
    expect(recipient.active_account.last4).to eq("7777")
    expect(recipient.active_account.bank_name).to eq("Bank Token Mocking")
  end

  it "retrieves a created token" do
    bank_token = StripeMock.generate_bank_token(
      :bank_name => "Cha-ching Banking",
      :last4 => "3939"
    )
    token = Stripe::Token.retrieve(bank_token)

    expect(token.id).to eq(bank_token)
    expect(token.bank_account.last4).to eq("3939")
    expect(token.bank_account.bank_name).to eq("Cha-ching Banking")
  end

end
