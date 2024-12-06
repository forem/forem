guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard :rspec, :cli => '-fs --color --order rand' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})    { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { 'spec' }
end

guard 'ctags-bundler', :emacs => true, :src_path => ['lib', 'spec/support'] do
  watch(%r{^(lib|spec/support)/.*\.rb$})
  watch('Gemfile.lock')
end
