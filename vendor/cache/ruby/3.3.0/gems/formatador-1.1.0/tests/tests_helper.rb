$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'formatador'
require 'rubygems'
require 'shindo'
require 'stringio'

class IO
  def tty?
    true
  end
end

class StringIO
  def tty?
    true
  end
end

def capture_stdout
  old_stdout = $stdout
  new_stdout = StringIO.new
  $stdout = new_stdout
  yield
  $stdout = old_stdout
  new_stdout.string
end
