class ContactController < ApplicationController
  layout 'layouts/card'

  # GET /users/1
  def index
    @user = User.find_by_long_token(params[:long_token])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with long token %{token}" % { :token => params[:long_token] }
    end
  end

  # POST /user/1
  def add_contact
    user = User.find_by_long_token(params[:long_token])
    if user == nil
      raise ActiveRecord::RecordNotFound, "No user with long token %{token}" % { :token => params[:long_token] }
    end

    response_status = user.add_contact(
      :first_name => params[:first_name],
      :last_name => params[:last_name],
      :phone => params[:phone]
    )

    if response_status == 201
      head :no_content
    else
      render json: { error: 'Failed to add the contact' }, status: :internal_server_error
    end
  end
end
