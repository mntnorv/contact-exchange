class RegistrationsController < Devise::RegistrationsController
  def update
    @user = User.find(current_user.id)

    successfully_updated = if needs_password?(@user, params)
      @user.update_with_password(devise_parameter_sanitizer.for(:account_update))
    else
      # Remove the virtual current_password attribute, update_attributes
      # doesn't know how to ignore it
      params[:user].delete(:current_password)
      @user.update_attributes(devise_parameter_sanitizer.for(:account_update))
    end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
    #else
    #  render "edit"
    end

    redirect_to after_update_path_for(@user)
  end

  ##
  # Check if the user needs a password for the changes
  # in params
  def needs_password?(user, params)
    user.encrypted_password != ""
  end

  ##
  # Returns the path to rederct to when a user signs up
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  ##
  # Redirect to the same path after password update
  def after_update_path_for(resource)
    URI.parse(request.referer).path if request.referer
  end

  ##
  # Permitted parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:password, :password_confirmation)
    end
  end
end