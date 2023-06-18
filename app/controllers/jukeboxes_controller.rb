class JukeboxesController < ApplicationController
  def new
    fetch_active_devices(current_user)
    fetch_playlists(current_user)
    @user = User.find(current_user.id)
    @jukebox = Jukebox.new(user: current_user)
    @devices = @user.devices.order(:name)
    @playlists = @user.playlists.order(:name)
    @cameras = []
  end

  def create
    @jukebox = Jukebox.new(jukebox_params)
    if @jukebox.valid? && @jukebox.save
      redirect_to @jukebox
    else
      flash[:notice] = "Jukebox konnte nicht erstellt werden. Bitte probieren Sie es erneut. Fehler: " + @jukebox.errors.full_messages.join(", ")
      redirect_to action: :new
    end
  end

  def show
    @jukebox = Jukebox.where(id: params[:id], user: current_user).first
    if @jukebox.blank?
      flash[:notice] = "Jukebox nicht gefunden. Bitte probieren Sie es erneut."
      redirect_to action: :new
    else
      @jukebox_title = @jukebox.name.presence || "Music"
      fetch_songs(@jukebox)
      currently_playing_and_queue = fetch_currently_playing_and_queue(@jukebox.user)
      @currently_playing_song = currently_playing_and_queue[:currently_playing]
      @queue = currently_playing_and_queue[:queue]
      @songs = @jukebox.songs.limit(240).order(:artist, :name)
      numbered_songs = LetterNumberCodes.add_number_and_letter_codes(@songs.pluck(:name, :artist, :id))
      @songs_per_page = numbered_songs.each_slice(60).to_a
      @num_of_pages = "page_#{(numbered_songs.length - 1) / 60 + 1}"
      render layout: "application-jukebox"
    end
  end

  def destroy
    jukebox = Jukebox.where(id: params[:id], user: current_user).first
    if jukebox.blank?
      flash[:notice] = "Jukebox nicht gefunden. Bitte probieren Sie es erneut."
    else
      jukebox = Jukebox.find(params[:id])
      jukebox.destroy
      flash[:notice] = "Jukebox gelöscht."
    end
    redirect_to root_path
  end

  def credits
    jukebox = Jukebox.find(params[:jukebox_id])
    operation = params[:operation]
    if operation == "add"
      new_credit = jukebox.credit + 1
    elsif operation == "remove"
      new_credit = jukebox.credit - 1
    end
    jukebox.update_attribute(:credit, new_credit)
    data = { new_credit: }

    render json: data
  end

  def add_song
    jukebox = Jukebox.find(params[:jukebox_id])
    song = Song.find(params[:song_id])

    SpotifyConnector.add_song_to_queue(jukebox, song)
    render json: ([credits: { amount: jukebox.credit }]).to_json
  end

  def playing_song
    jukebox = Jukebox.find(params[:jukebox_id])
    currently_playing_and_queue = fetch_currently_playing_and_queue(jukebox.user)
    currently_playing = currently_playing_and_queue[:currently_playing]
    queue = currently_playing_and_queue[:queue]
    render json: { currently_playing:, queue: }
  end

  def next_song
    jukebox = Jukebox.find(params[:jukebox_id])
    play_next_song(jukebox.user)

    head :ok
  end

  def control_playback
    jukebox = Jukebox.find(params[:jukebox_id])
    control_spotify_playback(jukebox.user)

    head :ok
  end

  def take_photo
    jukebox = Jukebox.find(params[:jukebox_id])
    song = Song.find(params[:song_id])
    decoded_base_sixty_four_img = Base64.decode64(params[:image])
    jukebox.images.attach(
      io: StringIO.new(decoded_base_sixty_four_img),
      filename: "#{song.artist} - #{song.name}",
      content_type: "image/png"
    )

    head :ok
  end

  private

  def jukebox_params
    params.require(:jukebox).permit(:name, :user_id, :device_id, :playlist_id, :camera_id, images: [])
  end

  def fetch_active_devices(user)
    SpotifyConnector.fetch_active_devices(user)
  end

  def fetch_playlists(user)
    SpotifyConnector.fetch_playlists(user)
  end

  def fetch_currently_playing_and_queue(user)
    SpotifyConnector.fetch_currently_playing_and_queue(user)
  end

  def fetch_songs(jukebox)
    SpotifyConnector.fetch_songs(jukebox)
  end

  def play_next_song(user)
    SpotifyConnector.play_next_song(user)
  end

  def control_spotify_playback(user)
    SpotifyConnector.start_or_stop_playback(user)
  end
end
