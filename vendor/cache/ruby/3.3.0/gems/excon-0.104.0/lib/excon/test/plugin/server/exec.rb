module Excon
  module Test
    module Plugin
      module Server
        module Exec
          def start(app_str = app)
            open_process(app_str)
            process_stderr = ""
            line = ''
            until line =~ /\Aready\Z/
              line = error.gets
              raise process_stderr if line.nil?
              process_stderr << line
              fatal_time = elapsed_time > timeout
              if fatal_time
                msg = "executable #{app_str} has taken too long to start"
                raise msg
              end
            end
            true
          end
        end
      end
    end
  end
end
