# A sample Guardfile
# More info at http://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch(/^spec\/(.*)_spec.rb/)
  watch(/^lib\/(.*)\.rb/)                              { "spec" }
  watch(/^spec\/spec_helper.rb/)                       { "spec" }
end
