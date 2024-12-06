require 'fog/aws/models/compute/key_pair'

module Fog
  module AWS
    class Compute
      class KeyPairs < Fog::Collection
        attribute :filters
        attribute :key_name

        model Fog::AWS::Compute::KeyPair

        # Used to create a key pair.  There are 3 arguments and only name is required.  You can generate a new key_pair as follows:
        # AWS.key_pairs.create(:name => "test", :fingerprint => "123", :private_key => '234234')
        #
        # ==== Returns
        #
        #<Fog::AWS::Compute::KeyPair
        #  name="test",
        #  fingerprint="3a:d3:e5:17:e5:e7:f7:de:fe:db:1b:c2:55:7d:94:0b:07:2e:05:aa",
        #  private_key="-----BEGIN RSA PRIVATE KEY-----\nf/VtfXJ/ekTSlRS2GSItBSzMrEGoZ+EXeMOuiA7HFkDcgKt6aBiOX9Bysiyfc1rIrgWdFKqXBRJA\nrtvBPa3/32koMPV4FxG7RZrPuKLITmFoEV86M0DSLo+ErlOPuDChfrR9dk6eI17/o1VmSvYsIpDc\njvbgx+tt7ZEPvduoUag7YdnUI0f20fttsdXjMlyDg9pPOVF3/hqucqOb3t5y9lvVJJxdTnEDFSjb\nvodpaDT9+ssw4IsQsZEIvfL0hK+Lt4phbclUWfG7JVnYfdd2u4zU6Nqe0+3qoR0ZOH4/zaUko7z8\n7JMbJqs5bmdWfnQTrvbJ13545FRI/W48ZRJxqPcj0t2MzasbT4gMgtNJrSadq78RkRJjNTu4lZmK\nvJejkBZPicHvo5IRSEbDc90Rhdh0aZNifXn0d0DSV2N6Ywo2o1lwRAi3/l6XSjukyRpTPcMr14MP\ntGwS1Tvez41Oa7Y96VfsJB2xtKc6LGRFiPUg2ZAEHU15Q9bIISVzHXgdAcef1bsh8UN/fDBrTusm\nvJisQ+dLaPH7cZ03od+XTwJc+IyeL4RqWuASE0NNfEVJMS+qcpt0WeNzfG0C27SwIcfEKL0sC0kn\nCfX2WpZDg7T5xN+88ftKJaN9tymxTgvoJVS1/WKvWBAXVozKp4f6K8wKmwf7VdUt/FWbUi54LW02\nf1ONkaYEOVwDgWlGxVSx43MWqvVdT2MPFNEBL7OA1LPwCO2nyQQ9UM9gCE65S9Najf939Bq8xwqx\nGNFlLmaH6biZUyL8ewRJ8Y7rMQ5cXy/gHZywjkuoyLQ8vVpmVpb7r1FaM/AYSr5l6gJEWdqbJleN\ntnhjPeE6qXISzIUBvwKzzgFTyW8ZHQtgbP3bHEiPG2/OjKHnLUoOId/eetcE+ovIxWsBrTDbf2SV\nYUD91u+W9K35eX89ZaIiohLNg4z9+QHCs4rcWyOXEfprBKcP2QU5+Y9ysnXLAmZt6QhInaAsUpQZ\nyhImA24UqvqrK0yyGhf/quouK7q0QkVQR+f7nGClIaphJkxO/xylrnK/pYObr4s3B8kmksuHiYOu\n1yz6SeRkj8F9dxkRmzbBK/G0tLkxIElDbM7icI9gsEO7vvgaR/K8hSDi0RkFPG43I20tU8PqwHe7\nR4jFW+6sB2+9FDeLn+qkoDSaxzmAuIRW082z/r7rJVIpFEo14hNhQYkNXpH40+P/hA9RFgvhZe8M\nvK4rz/eu246Kij6kObieTfpZhgGHqvtU8x5cnqEZOz5Hc5m4B+gMaTA53kFSPOA0pn6gqgiuYEdI\nZUhO8P1PkNqkmLz7NJRnz3qpAo6RisAxPBVr2WdSg4bP0YpGS/0TE4OOJwGLldx6dCsX60++mn0q\n1fhNw8oyZiguYMAeEEDWP8x/bsRaFz5L8uQVnnnj8ei1oTmZ+Uw9/48snWYcurL2jsbuWhhE0NTt\nfe/cqov7ZaZHs+Tr20ZBEDEqUEWr/MMskj/ZSVxnza1G/hztFJMAThF9ZJoGQkHWHfXCGOLLGY+z\nqi0SC8EIeu8PUxjO2SRj9S9o/Dwg3iHyM3pj57kD7fDNnl3Ed6LMoCXoaQV8BdMX4xh=\n-----END RSA PRIVATE KEY-----"
        #>
        #
        # The key_pair can be retrieved by running AWS.key_pairs.get("test").  See get method below.
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all key pairs that have been created
        #
        # AWS.key_pairs.all
        #
        # ==== Returns
        #
        # <Fog::AWS::Compute::KeyPairs
        #  key_name=nil
        #  [
        #    <Fog::AWS::Compute::KeyPair
        #      name="test",
        #      fingerprint="1f:26:3d:83:e7:4f:48:74:c3:1c:e6:b3:c7:f6:ec:d8:cb:09:b3:7f",
        #      private_key=nil
        #    >
        #  ]
        #>
        #

        def all(filters_arg = filters)
          unless filters_arg.is_a?(Hash)
            Fog::Logger.deprecation("all with #{filters_arg.class} param is deprecated, use all('key-name' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'key-name' => [*filters_arg]}
          end
          filters = filters_arg
          data = service.describe_key_pairs(filters).body
          load(data['keySet'])
        end

        # Used to retrieve a key pair that was created with the AWS.key_pairs.create method.
        # The name is required to get the associated key_pair information.
        #
        # You can run the following command to get the details:
        # AWS.key_pairs.get("test")
        #
        # ==== Returns
        #
        #>> AWS.key_pairs.get("test")
        #  <Fog::AWS::Compute::KeyPair
        #    name="test",
        #    fingerprint="1f:26:3d:83:e7:4f:48:74:c3:1c:e6:b3:c7:f6:ec:d8:cb:09:b3:7f",
        #    private_key=nil
        #  >
        #

        def get(key_name)
          if key_name
            self.class.new(:service => service).all('key-name' => key_name).first
          end
        end
      end
    end
  end
end
