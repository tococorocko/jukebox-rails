class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :spotify

  def spotify
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      @user.update(
        access_token: request.env["omniauth.auth"].credentials.token,
        refresh_token: request.env["omniauth.auth"].credentials.refresh_token
      )
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "Spotify") if is_navigational_format?
    else
      session["devise.spotify_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end

