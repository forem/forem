require 'spec_helper'

shared_examples 'Extra Features' do

  it "can set the global id prefix" do
    StripeMock.global_id_prefix = "custom_prefix_"
    expect(StripeMock.global_id_prefix).to eq("custom_prefix_")

    customer = Stripe::Customer.create
    expect(customer.id).to match /^custom_prefix_cus/
    StripeMock.global_id_prefix = nil
  end

  it "can set the global id prefix to nothing" do
    StripeMock.global_id_prefix = ""
    expect(StripeMock.global_id_prefix).to eq("")

    customer = Stripe::Customer.create
    expect(customer.id).to match /^cus/

    # Support false
    StripeMock.global_id_prefix = false
    expect(StripeMock.global_id_prefix).to eq("")

    customer = Stripe::Customer.create
    expect(customer.id).to match /^cus/
    StripeMock.global_id_prefix = nil
  end

  it "has a default global id prefix" do
    StripeMock.global_id_prefix = nil
    expect(StripeMock.global_id_prefix).to eq("test_")
    customer = Stripe::Customer.create
    expect(customer.id).to match /^test_cus/
  end
end
