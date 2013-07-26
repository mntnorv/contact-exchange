class UserPageController < ApplicationController
  layout 'layouts/simple_form'

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
      redirect_to user_page_url(user.long_token), notice: "Contact was successfully added."
    else
      redirect_to user_page_url(user.long_token), alert: "Error: adding the contact failed."
    end
  end
end