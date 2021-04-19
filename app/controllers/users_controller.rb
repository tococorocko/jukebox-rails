class UsersController < ApplicationController
  def show
    @jukeboxes = Jukebox.where(user: current_user).with_attached_images
  end
end
