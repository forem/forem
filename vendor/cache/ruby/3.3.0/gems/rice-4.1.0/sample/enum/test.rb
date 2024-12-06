require_relative 'sample_enum'

Sample_Enum.each { |x| p x }
s = Sample_Enum::FOO
puts s
puts s.inspect
puts s < Sample_Enum::BAR
s.description
