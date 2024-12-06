module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Returns AWS resources for this environment.
        #
        # ==== Options
        # * EnvironmentId
        # * EnvironmentName
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_RestartAppServer.html
        #
        def restart_app_server(options={})
          request({
                      'Operation'    => 'RestartAppServer',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
