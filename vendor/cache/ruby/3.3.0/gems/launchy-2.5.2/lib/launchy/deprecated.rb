module Launchy
  #
  # This class is deprecated and will be removed 
  #
  class Browser
    def self.run( *args )
      Browser.new.visit( args[0] )
    end

    def visit( url )
      _warn "You made a call to a deprecated Launchy API. This call should be changed to 'Launchy.open( uri )'"
      report_caller_context( caller )

      ::Launchy.open( url )
    end

    private

    def find_caller_context( stack )
      caller_file = stack.find do |line|
        not line.index( __FILE__ )
      end
      if caller_file then
        caller_fname, caller_line, _ = caller_file.split(":")
        if File.readable?( caller_fname ) then
          caller_lines = IO.readlines( caller_fname )
          context = [ caller_file ]
          context << caller_lines[(caller_line.to_i)-3, 5] 
          return context.flatten
        end
      end
      return []
    end

    def report_caller_context( stack )
      context = find_caller_context( stack )
      if context.size > 0 then
        _warn "I think I was able to find the location that needs to be fixed. Please go look at:"
        _warn
        context.each do |line|
          _warn line.rstrip
        end
        _warn
        _warn "If this is not the case, please file a bug. #{Launchy.bug_report_message}"
      end
    end

    def _warn( msg = "" )
      warn "WARNING: #{msg}"
    end
  end
end
