class RegistrationsController < Devise::RegistrationsController
  def update
    @user = User.find(current_user.id)

    successfully_updated = if needs_password?(@user, params)
      @user.update_with_password(update)
    else
      # Remove the virtual current_password attribute, update_attributes
      # doesn't know how to ignore it
      params[:user].delete(:current_password)
      @user.update_attributes(update_params)
    end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
    end

    redirect_to profile_path
  end

  ##
  # Check if the user needs a password for the changes
  # in params
  def needs_password?(user, params)
    !user.encrypted_password.empty?
  end

  ##
  # Returns the path to redirect to when a user signs up
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  ##
  # Redirect to profile path after update
  def after_update_path_for(resource)
    profile_path
  end

  ##
  # Permitted parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:password, :password_confirmation)
    end
  end

  private

  ##
  # Account update params
  def update_params
    devise_parameter_sanitizer.sanitize(:account_update)
  end
end
