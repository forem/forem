# frozen_string_literal: true

module KnapsackPro
  module Crypto
    class BranchEncryptor
      NON_ENCRYPTABLE_BRANCHES = [
        'master',
        'main',
        'develop',
        'development',
        'dev',
        'staging',
        'production',
        # GitHub Actions has branch names starting with refs/heads/
        'refs/heads/master',
        'refs/heads/main',
        'refs/heads/develop',
        'refs/heads/development',
        'refs/heads/dev',
        'refs/heads/staging',
        'refs/heads/production',
      ]

      def self.call(branch)
        if KnapsackPro::Config::Env.branch_encrypted?
          new(branch).call
        else
          branch
        end
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        if NON_ENCRYPTABLE_BRANCHES.include?(branch)
          branch
        else
          Digestor.salt_hexdigest(branch)[0..6]
        end
      end

      private

      attr_reader :branch
    end
  end
end
