# frozen_string_literal: true

require 'pathname'

class ActiveRecordData
  class << self
    data_file_selector = Pathname(File.dirname(__FILE__)).join('active_record_data', '*.txt')

    # Example generated method
    # data_filename = '/path/to/ap/spec/support/active_record_data/4_2_diana.txt'
    #
    # def self.raw_4_2_dana
    #   File.read(data_filename).strip
    # end
    Dir[data_file_selector].each do |data_filename|
      method_name = Pathname(data_filename).basename('.txt')
      define_method(:"raw_#{method_name}") do
        File.read(data_filename).strip
      end
    end
  end
end
