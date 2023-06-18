class Users::SessionsController < Devise::SessionsController
  def destroy
    begin
      current_user.songs.each(&:destroy)
    rescue StandardError
      nil
    end
    super
  end
end
