class SignupsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_signup_path, alert: "Try again later." }

  def new
    return redirect_to root_path if authenticated?
    return redirect_to new_session_path unless Team.accepting_signups?

    @user = User.new
    render(Team.first_run? ? :first_run : :new)
  end

  def create
    return redirect_to new_session_path unless Team.accepting_signups?

    @user = User.new(signup_params)
    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      render(Team.first_run? ? :first_run : :new, status: :unprocessable_entity)
    end
  end

  private

  def signup_params
    params.require(:signup).permit(:email_address, :password, :password_confirmation)
  end
end
