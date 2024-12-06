require 'spec_helper'

module Polyamorous
  describe "ActiveRecord Compatibility" do
    it 'works with self joins and includes' do
      trade_account = Account.create!
      Account.create!(trade_account: trade_account)

      accounts = Account.joins(:trade_account).includes(:trade_account, :agent_account)
      account = accounts.first

      expect(account.agent_account).to be_nil
    end
  end
end
