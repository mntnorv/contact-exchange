class ErrorController < ApplicationController

  def error_404
    render '404', status: :not_found
  end

end
