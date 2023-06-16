class Users::SessionsController < Devise::SessionsController
  def destroy
    begin
      current_user.queued_songs.each(&:destroy)
    rescue StandardError
      nil
    end
    begin
      current_user.songs.each(&:destroy)
    rescue StandardError
      nil
    end
    super
  end
end
