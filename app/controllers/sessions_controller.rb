class SessionsController < Devise::SessionsController
    def new
      super
    end
  
    def create
      self.resource = warden.authenticate!(auth_options)
      parameter = params[:user]
      address = parameter[:address] ? parameter[:address] : ''
      if address.length
        res = Faraday.get 'https://algoexplorerapi.io/idx2/v2/accounts/' + address
        body = JSON.parse(res.body)
        if body['account']
          balance = body['account']['assets'][0]['amount']
          Rails.logger.debug("balance@@=>: #{balance}")
          if balance.to_i >= 100000000
            if resource.nil?
              redirect_back(fallback_location: root_path)
            end
            sign_in(resource_name, resource)
            redirect_to root_path(signin: "true")
          else  
            redirect_back(fallback_location: root_path)
          end
        else 
          redirect_back(fallback_location: root_path)
        end
      else
        set_flash_message(:notice, :signed_in) if is_navigational_format?
        redirect_back(fallback_location: root_path)
      end
    end
  end
  