require 'spec_helper'
require_stripe_examples

describe StripeMock::Instance do

  let(:stripe_helper) { StripeMock.create_test_helper }

  it_behaves_like_stripe do
    def test_data_source(type); StripeMock.instance.send(type); end
  end

  before { StripeMock.start }
  after { StripeMock.stop }

  it "handles both string and symbol hash keys" do
    symbol_params = stripe_helper.create_product_params(
      :name => "Symbol Product",
      "type" => "service"
    )
    res, api_key = StripeMock.instance.mock_request('post', '/v1/products', api_key: 'api_key', params: symbol_params)
    expect(res.data[:name]).to eq('Symbol Product')
    expect(res.data[:type]).to eq('service')
  end

  it "exits gracefully on an unrecognized handler url" do
    dummy_params = {
      "id" => "str_12345",
      "name" => "PLAN"
    }

    expect { res, api_key = StripeMock.instance.mock_request('post', '/v1/unrecongnized_method', api_key: 'api_key', params: dummy_params) }.to_not raise_error
  end

  it "can toggle debug" do
    StripeMock.toggle_debug(true)
    expect(StripeMock.instance.debug).to eq(true)
    StripeMock.toggle_debug(false)
    expect(StripeMock.instance.debug).to eq(false)
  end

  it "should toggle off debug when mock session ends" do
    StripeMock.toggle_debug(true)

    StripeMock.stop
    expect(StripeMock.instance).to be_nil

    StripeMock.start
    expect(StripeMock.instance.debug).to eq(false)
  end

  it "can set a conversion rate" do
    StripeMock.set_conversion_rate(1.25)
    expect(StripeMock.instance.conversion_rate).to eq(1.25)
  end

  it "allows non-usd default currency" do
    pending("Stripe::Plan requires currency param - how can we test this?")
    old_default_currency = StripeMock.default_currency
    plan = begin
      StripeMock.default_currency = "jpy"
      Stripe::Plan.create(interval: 'month')
    ensure
      StripeMock.default_currency = old_default_currency
    end
    expect(plan.currency).to eq("jpy")
  end

  context 'when creating sources with metadata' do
    let(:customer) { Stripe::Customer.create(email: 'test@email.com') }
    let(:metadata) { { test_key: 'test_value' } }

    context 'for credit card' do
      let(:credit_card) do
        customer.sources.create(
          source: stripe_helper.generate_card_token,
          metadata: metadata
        )
      end

      it('should save metadata') do
        expect(credit_card.metadata.test_key).to eq metadata[:test_key]
      end
    end

    context 'for bank account' do
      let(:bank_account) do
        customer.sources.create(
          source: stripe_helper.generate_bank_token,
          metadata: metadata
        )
      end

      it('should save metadata') do
        expect(bank_account.metadata.test_key).to eq metadata[:test_key]
      end
    end
  end
end
