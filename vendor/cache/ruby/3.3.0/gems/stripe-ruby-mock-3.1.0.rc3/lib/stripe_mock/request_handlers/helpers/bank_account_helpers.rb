module StripeMock
  module RequestHandlers
    module Helpers

      def verify_bank_account(object, bank_account_id, class_name='Customer')
        bank_accounts = object[:external_accounts] || object[:bank_accounts] || object[:sources]
        bank_account = bank_accounts[:data].find{|acc| acc[:id] == bank_account_id }
        return if bank_account.nil?
        bank_account['status'] = 'verified'
        bank_account
      end
    end
  end
end
