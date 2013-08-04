require 'signet/oauth_2/client'

class UsersController < ApplicationController

  layout 'layouts/simple_form'

  # GET /users/1
  def show
    @user = User.find_by_user_token(params[:token])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with token %{token}" % { :token => params[:token] }
    end
  end

  # GET /users/register
  def register
    @user = User.new

    if params[:code] == nil
      redirect_uri = @user.oauth_client.authorization_uri
      redirect_to redirect_uri.to_s
    else
      @user.fetch_new_tokens! params[:code]
      @user.update_user_info!

      # Check if there isn't a user already registered with
      # the email
      registered_user = User.find_by_email(@user.email)
      
      if registered_user != nil
        redirect_to user_url(registered_user.user_token), notice: 'You were already registered.'
      else
        # Raises an exception if saving failed
        # Use 'if @user.save ... else .. end' if any
        # exception handling is needed
        @user.save!
        redirect_to user_url(@user.user_token), notice: 'User was successfully created.'
      end
    end
  end

  # POST /users/1/add_contact
  def add_contact
    @user = User.find_by_user_token(params[:token])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with token %{token}" % { :token => params[:token] }
    end

    response = @user.add_contact(
      :first_name => params[:first_name],
      :last_name => params[:last_name],
      :phone => params[:phone]
    )

    if response.status == 201
      redirect_to user_url(@user.user_token), notice: "Contact was successfully added."
    else
      redirect_to user_url(@user.user_token), alert: "Error: adding the contact failed."
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find_by_user_token(params[:token])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with token %{token}" % { :token => params[:token] }
    end

    @user.destroy

    redirect_to users_url
  end

  private
    def user_params
      params.require(:user).permit(:email, :name)
    end
end
