class ApplicationController < ActionController::Base
  protect_from_forgery

  def after_sign_in_path_for(resource_or_scope)
    profile_path
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  rescue_from 'ActionController::RoutingError' do |exception|
    redirect_to error_404_path
  end

  def success_toast(message)
    toast('success', message)
  end

  def error_toast(message)
    toast('error', message)
  end

  def toast(type, message)
    flash[:toasts] ||= []
    flash[:toasts] << {
      type: type,
      message: message
    }
  end
end
