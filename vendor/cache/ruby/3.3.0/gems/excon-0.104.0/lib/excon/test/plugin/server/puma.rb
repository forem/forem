module Excon
  module Test
    module Plugin
      module Server
        module Puma
          def start(app_str = app, bind_uri = bind)
            open_process(RbConfig.ruby, '-S', 'puma', '-b', bind_uri.to_s, app_str)
            process_stderr = ""
            line = ''
            until line =~ /Use Ctrl-C to stop/
              line = read.gets
              raise process_stderr if line.nil?
              process_stderr << line
              fatal_time = elapsed_time > timeout
              raise 'puma server has taken too long to start' if fatal_time
            end
            true
          end
        end
      end
    end
  end
end
