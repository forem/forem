module Fog
  module AWS
    class ELB
      class Policy < Fog::Model
        identity :id, :aliases => 'PolicyName'

        attribute :cookie,     :aliases => 'CookieName'
        attribute :expiration, :aliases => 'CookieExpirationPeriod'
        attribute :type_name
        attribute :policy_attributes
        attribute :load_balancer_id

        attr_accessor :cookie_stickiness # Either :app or :lb

        def save
          requires :id, :load_balancer_id
          args = [load_balancer_id, id]

          if cookie_stickiness
            case cookie_stickiness
            when :app
              requires :cookie
              method = :create_app_cookie_stickiness_policy
              args << cookie
            when :lb
              method = :create_lb_cookie_stickiness_policy
              args << expiration if expiration
            else
              raise ArgumentError.new('cookie_stickiness must be :app or :lb')
            end
          else
            requires :type_name, :policy_attributes
            method = :create_load_balancer_policy
            args << type_name
            args << policy_attributes
          end

          service.send(method, *args)
          reload
        end

        def destroy
          requires :identity, :load_balancer_id

          service.delete_load_balancer_policy(self.load_balancer_id, self.identity)
          reload
        end

        def load_balancer
          requires :load_balancer_id

          service.load_balancers.new(:identity => self.load_balancer_id)
        end
      end
    end
  end
end
