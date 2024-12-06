# frozen_string_literal: true

class ApplicationController < ActionController::Base
  if respond_to?(:before_filter) && !respond_to?(:before_action)
    class << self
      alias :before_action :before_filter
    end
  end

  protect_from_forgery
  before_action :pull_out_locale


  def pull_out_locale
    I18n.locale = params[:locale] if params[:locale].present?
  end
end
