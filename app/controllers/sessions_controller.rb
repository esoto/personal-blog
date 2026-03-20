class SessionsController < ApplicationController
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 5, within: 1.minute, only: :create, store: RATE_LIMIT_STORE

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user
      reset_session
      session[:user_id] = user.id
      redirect_to admin_root_path, notice: "Logged in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out."
  end
end
