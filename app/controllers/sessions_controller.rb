class SessionsController < Devise::SessionsController
    def new
      super
    end
  
    def create
      self.resource = warden.authenticate!(auth_options)
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      parameter = params[:user]
      address = parameter[:address] ? parameter[:address] : ''
      if address.length
        res = Faraday.get 'https://algoexplorerapi.io/idx2/v2/accounts/' + address
        balance = JSON.parse(res.body)['account']['assets'][0]['amount']
        if balance.to_i >= 100000000
          sign_in(resource_name, resource)
          redirect_to root_path(signin: "true")
        else
          return false
        end
      end
    end
  end
  