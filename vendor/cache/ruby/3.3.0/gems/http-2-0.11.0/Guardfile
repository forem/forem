guard :process, name: 'HTTP/2 Server', command: 'ruby example/server.rb', stop_signal: 'TERM' do
  watch(%r{^example/(.+)\.rb$})
  watch(%r{^lib/http/2/(.+)\.rb$})

  watch('Gemfile.lock')
end

def h2spec
  puts 'Starting H2 Spec'
  sleep 0.7
  system '~/go-workspace/bin/h2spec -p 8080 -o 1 -s 4.2'
  puts "\n"
end

guard :shell, name: 'H2 Spec' do
  watch(%r{^example/(.+)\.rb$})    { h2spec }
  watch(%r{^lib/http/2/(.+)\.rb$}) { h2spec }
end
