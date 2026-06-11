require "rails_helper"

RSpec.describe RequestStore do
  before do
    RequestStore.clear!
  end

  after do
    RequestStore.clear!
  end

  it "stores and retrieves values" do
    RequestStore.store[:test_key] = "test_value"
    expect(RequestStore.store[:test_key]).to eq("test_value")
  end

  it "clears values on clear!" do
    RequestStore.store[:test_key] = "test_value"
    RequestStore.clear!
    expect(RequestStore.store[:test_key]).to be_nil
  end

  it "isolates values between threads" do
    RequestStore.store[:test_key] = "main_thread_value"

    other_thread_value = nil
    t = Thread.new do
      RequestStore.store[:test_key] = "other_thread_value"
      other_thread_value = RequestStore.store[:test_key]
    end
    t.join

    expect(other_thread_value).to eq("other_thread_value")
    expect(RequestStore.store[:test_key]).to eq("main_thread_value")
  end
end
