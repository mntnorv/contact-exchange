class RegistrationsController < Devise::RegistrationsController
  def update
    @user = User.find(current_user.id)
    reload = false

    successfully_updated = if needs_password?(@user, params)
      @user.update_with_password(update_params)
    else
      # Remove the virtual current_password attribute, update_attributes
      # doesn't know how to ignore it
      params[:user].delete(:current_password)
      @user.update_attributes(update_params)
      reload = true
    end

    if successfully_updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true

      if reload
        success_toast('Updated successfully')
        render json: { reload: true }
      else
        render json: { toast: { type: 'success', message: 'Updated successfully' } }
      end
    else
      render json: { errors: @user.errors.messages }, status: :unprocessable_entity
    end
  end

  ##
  # Check if the user needs a password for the changes
  # in params
  def needs_password?(user, params)
    !user.encrypted_password.blank?
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
