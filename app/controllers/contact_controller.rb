class ContactController < ApplicationController
  layout 'layouts/card'

  # GET /users/1
  def index
    @user = User.find_by_long_token(params[:long_token]) || not_found
  end

  # POST /user/1
  def add_contact
    user = User.find_by_long_token(params[:long_token]) || not_found

    response_status = user.add_contact(contact_params)

    if response_status
      render json: { toast: {
        type: :success,
        message: 'Contact added'
      }}
    else
      render json: { error: 'Failed to add the contact' }, status: :internal_server_error
    end
  end

  private

  def contact_params
    params.permit(:first_name, :last_name, :phone)
  end
end
