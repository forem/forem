# frozen_string_literal: true

module KnapsackPro
  module Crypto
    class Decryptor
      class TooManyEncryptedTestFilesError < StandardError; end

      def self.call(test_files, encrypted_test_files)
        if KnapsackPro::Config::Env.test_files_encrypted?
          new(test_files, encrypted_test_files).call
        else
          # those test files are not encrypted
          encrypted_test_files
        end
      end

      def initialize(test_files, encrypted_test_files)
        @test_files = test_files
        @encrypted_test_files = encrypted_test_files
      end

      def call
        decrypted_test_files = []

        test_files.each do |test_file|
          encrypted_path = Digestor.salt_hexdigest(test_file['path'])
          encrypted_test_file = find_encrypted_test_file(encrypted_path)
          next if encrypted_test_file.nil?

          decrypted_test_file = encrypted_test_file.dup
          decrypted_test_file['path'] = test_file['path']

          decrypted_test_files << decrypted_test_file
        end

        decrypted_test_files
      end

      private

      attr_reader :test_files,
        :encrypted_test_files

      def find_encrypted_test_file(encrypted_path)
        test_files = encrypted_test_files.select do |t|
          t['path'] == encrypted_path
        end

        if test_files.size == 1
          test_files.first
        elsif test_files.size > 1
          raise TooManyEncryptedTestFilesError.new("Found more than one encrypted test file for encrypted path #{encrypted_path}")
        end
      end
    end
  end
end
