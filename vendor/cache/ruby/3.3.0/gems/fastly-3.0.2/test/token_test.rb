require 'helper'

# Testing client components related to tokens
class Fastly
  describe 'TokenTest' do
    let(:opts)             { login_opts(:both) }
    let(:fastly)           { Fastly.new(opts) }

    let(:service_name) { "fastly-test-service-#{random_string}" } 
    let(:service) { fastly.create_service(:name => service_name) }
    let(:current_customer) { fastly.current_customer }

    def create_a_test_token(name, service, scope)
      fastly.new_token(
          name: name,
          services: service,
          scope: scope
      )      
    end

    it 'creates a new token' do
      token = create_a_test_token('name_vi',service.id,'purge_all purge_select')
      assert_equal token.name, 'name_vi'
      assert_equal token.services[0], service.id
      assert_equal token.scope, 'purge_all purge_select'
      fastly.delete_token(token)
    end
    
    it 'deletes a token by passed-in token' do
        token = create_a_test_token('name_vi',service.id,'purge_all purge_select')
        
        tokens = fastly.customer_tokens({customer_id: current_customer.id})
        before_count = tokens.count
        
        fastly.delete_token(token)
        
        tokens = fastly.customer_tokens({customer_id: current_customer.id})
        after_count = tokens.count

        assert_equal 1, before_count - after_count
    end
      
    it 'returns a list of tokens belonging to the customer or to the auth token' do
      @token_i = create_a_test_token('name_i',service.id,'purge_all purge_select')
      @token_ii = create_a_test_token('name_ii',service.id,'purge_all purge_select')
      @token_iii = create_a_test_token('name_iii',service.id,'purge_all purge_select')
      @token_iv = create_a_test_token('name_iv',service.id,'purge_all purge_select')
      @token_v = create_a_test_token('name_v',service.id,'purge_all purge_select')

      tokens = fastly.customer_tokens({customer_id: current_customer.id})
      assert tokens.count > 4

      tokens = fastly.list_tokens
      assert tokens.count > 4

      fastly.delete_token(@token_i)
      fastly.delete_token(@token_ii)
      fastly.delete_token(@token_iii)
      fastly.delete_token(@token_iv)
      fastly.delete_token(@token_v)
      fastly.delete_service(service)
    end
  end
end
