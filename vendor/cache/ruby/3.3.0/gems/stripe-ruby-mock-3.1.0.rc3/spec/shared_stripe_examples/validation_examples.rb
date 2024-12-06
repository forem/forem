require 'spec_helper'

shared_examples 'Server Validation', :live => true do

  def credit_card_valid?(account_number)
    digits = account_number.scan(/./).map(&:to_i)
    check = digits.pop

    sum = digits.reverse.each_slice(2).map do |x, y|
      [(x * 2).divmod(10), y || 0]
    end.flatten.inject(:+)

    (10 - sum % 10) == check
  end

  it "runs a luhn check for charges" do
    Stripe::Charge.new :with => "4242424242424241"
  end
end
