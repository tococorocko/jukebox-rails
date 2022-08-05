class Users::SessionsController < Devise::SessionsController
  def destroy
    current_user.queued_songs.each(&:destroy) rescue nil
    current_user.songs.each(&:destroy) rescue nil
    super
  end
end