# -*- ruby -*-

require 'hoe'

Hoe.plugin :bundler
Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :travis

Hoe.spec 'net-http-persistent' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  self.readme_file      = 'README.rdoc'
  self.extra_rdoc_files += Dir['*.rdoc']

  self.require_ruby_version '>= 2.3'

  license 'MIT'

  rdoc_locations <<
    'docs-push.seattlerb.org:/data/www/docs.seattlerb.org/net-http-persistent/'

  dependency 'connection_pool',   '~> 2.2'
  dependency 'minitest',          '~> 5.2', :development
  dependency 'hoe-bundler',       '~> 1.5', :development
  dependency 'hoe-travis',        ['~> 1.4', '>= 1.4.1'], :development
  dependency 'net-http-pipeline', '~> 1.0' if
    ENV['TRAVIS_MATRIX'] == 'pipeline'
end

# vim: syntax=Ruby
