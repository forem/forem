require 'rack/request'
require 'uri'

class Rack::HostRedirect

  def initialize(app, host_mapping)
    @app = app
    @host_mapping = preprocess_mapping(host_mapping)
  end

  def call(env)
    request = Rack::Request.new(env)
    
    if updated_uri_opts = get_updated_uri_opts(request)
      location = update_url(request.url, updated_uri_opts)
      [301, {'Location' => location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    else
      @app.call(env)
    end
  end

  private

    def preprocess_mapping hsh
      hsh.inject({}) do |out, (k, opts)| 
        opts = {:host => opts} if opts.is_a?(String)
        
        if newhost = opts[:host]
          opts[:host] = newhost.downcase
        else
          raise ArgumentError, ":host key must be specified in #{opts.inspect}"
        end

        exclude_proc = opts.delete(:exclude)

        [k].flatten.each do |oldhost|
          oldhost = oldhost.downcase

          if oldhost == opts[:host]
            raise ArgumentError, "#{oldhost.inspect} is being redirected to itself"
          else
            out[oldhost] = [opts, exclude_proc]
          end
        end

        out
      end
    end

    def get_updated_uri_opts request
      host = request.host.downcase # downcase for case-insensitive matching
      uri_opts, exclude_proc = @host_mapping[host]
      uri_opts unless exclude_proc && exclude_proc.call(request)
    end

    def update_url url, opts
      uri = URI(url)

      opts.each do |k, v| 
        uri.send(:"#{k}=", v)
      end

      uri.to_s
    end
end
