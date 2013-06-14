require 'signet/oauth_2/client'

class UsersController < ApplicationController
  # GET /users/1
  def show
    @user = User.find_by_user_hash(params[:hash])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with hash %{hash}" % { :hash => params[:hash] }
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

      begin
        if @user.save
          redirect_to user_url(@user.user_hash), notice: 'User was successfully created.'
        else
          # Error: failed saving user
          render json: @user, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        redirect_to user_url(@user.user_hash), notice: 'You were already registered.'
      end
    end
  end

  # POST /users/1/add_contact
  def add_contact
    @user = User.find_by_user_hash(params[:hash])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with hash %{hash}" % { :hash => params[:hash] }
    end

    response = @user.add_contact(
      :first_name => params[:first_name],
      :last_name => params[:last_name],
      :phone => params[:phone]
    )

    if response.status == 201
      redirect_to user_url(@user.user_hash), notice: "Contact was successfully added."
    else
      # Error, didn't add contact
      redirect_to user_url(@user.user_hash)
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find_by_user_hash(params[:hash])
    if @user == nil
      raise ActiveRecord::RecordNotFound, "No user with hash %{hash}" % { :hash => params[:hash] }
    end

    @user.destroy

    redirect_to users_url
  end
end
