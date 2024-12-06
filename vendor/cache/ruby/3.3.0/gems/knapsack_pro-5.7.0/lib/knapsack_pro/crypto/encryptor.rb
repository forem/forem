# frozen_string_literal: true

module KnapsackPro
  module Crypto
    class Encryptor
      def self.call(test_files)
        if KnapsackPro::Config::Env.test_files_encrypted?
          new(test_files).call
        else
          test_files
        end
      end

      def initialize(test_files)
        @test_files = test_files
      end

      def call
        encrypted_test_files = []

        test_files.each do |test_file|
          test_file_dup = test_file.dup
          test_file_dup['path'] = Digestor.salt_hexdigest(test_file['path'])
          encrypted_test_files << test_file_dup
        end

        encrypted_test_files
      end

      private

      attr_reader :test_files
    end
  end
end
