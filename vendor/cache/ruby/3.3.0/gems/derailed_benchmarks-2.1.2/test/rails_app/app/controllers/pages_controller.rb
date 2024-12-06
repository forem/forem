# frozen_string_literal: true

class PagesController < ApplicationController
  http_basic_authenticate_with name: "admin", password: "secret", only: :secret

  def index
  end

  def secret
    render action: 'index'
  end

  private
end
