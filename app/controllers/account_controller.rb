class AccountController < ApplicationController
  before_filter :authenticate_user!

  # GET account
  def index
  end
end