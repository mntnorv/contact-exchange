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
    client = new_auth_client

    if params[:code] == nil
      redirect_uri = client.authorization_uri
      redirect_to redirect_uri.to_s
    else
      @user = User.new

      client.code = params[:code]
      client.fetch_access_token!

      @user.update_user_info! client

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

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:hash])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:hash])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  # Get default google client
  private
  def new_auth_client
    client = Signet::OAuth2::Client.new(
      :authorization_uri    => Yetting.google_auth_uri,
      :token_credential_uri => Yetting.google_token_uri,
      :client_id            => Yetting.google_client_id,
      :client_secret        => Yetting.google_client_secret,
      :redirect_uri         => Yetting.google_callback,
      :scope                => Yetting.google_api_scopes
    )
  end
end
