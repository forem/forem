require 'fog/aws/models/elb/policy'

module Fog
  module AWS
    class ELB
      class Policies < Fog::Collection

        attribute :load_balancer_id

        model Fog::AWS::ELB::Policy

        def all(options={})
          merge_attributes(options)

          requires :load_balancer_id

          data = service.describe_load_balancer_policies(self.load_balancer_id).
            body["DescribeLoadBalancerPoliciesResult"]["PolicyDescriptions"]

          load(munge(data))
        end

        def get(id)
          all.find { |policy| id == policy.id }
        end

        def new(attributes={})
          super(self.attributes.merge(attributes))
        end

        private

        def munge(data)
          data.reduce([]) { |m,e|
            policy_attribute_descriptions = e["PolicyAttributeDescriptions"]

            policy = {
              :id                => e["PolicyName"],
              :type_name         => e["PolicyTypeName"],
              :policy_attributes => policy_attributes(policy_attribute_descriptions),
              :load_balancer_id  => self.load_balancer_id,
            }

            case e["PolicyTypeName"]
            when 'AppCookieStickinessPolicyType'
              cookie_name = policy_attribute_descriptions.find{|h| h['AttributeName'] == 'CookieName'}['AttributeValue']
              policy['CookieName'] = cookie_name if cookie_name
            when 'LBCookieStickinessPolicyType'
              cookie_expiration_period = policy_attribute_descriptions.find{|h| h['AttributeName'] == 'CookieExpirationPeriod'}['AttributeValue'].to_i
              policy['CookieExpirationPeriod'] = cookie_expiration_period if cookie_expiration_period > 0
            end

            m << policy
            m
          }
        end

        def policy_attributes(policy_attribute_descriptions)
          policy_attribute_descriptions.reduce({}){|m,e|
            m[e["AttributeName"]] = e["AttributeValue"]
            m
          }
        end
      end
    end
  end
end
