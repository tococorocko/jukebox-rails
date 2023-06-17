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
      flash[:notice] = 'Jukebox konnte nicht erstellt werden. Bitte probieren Sie es erneut. Fehler: ' + @jukebox.errors.full_messages.join(', ')
      redirect_to action: :new
    end
  end

  def show
    @jukebox = Jukebox.where(id: params[:id], user: current_user).first
    if @jukebox.blank?
      flash[:notice] = 'Jukebox nicht gefunden. Bitte probieren Sie es erneut.'
      redirect_to action: :new
    else
      @jukebox_title = @jukebox.name.presence || "Music"
      fetch_songs(@jukebox)
      @currently_playing_song = fetch_playing_song(@jukebox.user)
      @songs = @jukebox.songs.limit(240).order(:artist, :name)
      numbered_songs = LetterNumberCodes.add_number_and_letter_codes(@songs.pluck(:name, :artist, :id))
      @songs_per_page = numbered_songs.each_slice(60).to_a
      @num_of_pages = "page_#{(numbered_songs.length - 1) / 60 + 1}"
      queue = []
      @jukebox.queued_songs.limit(5).each do |queued_song|
        jukebox_song = Song.find_by_uri(queued_song.song_uri)
        queue.push([jukebox_song.name, jukebox_song.artist])
      end
      @queued_songs = queue

      render layout: "application-jukebox"
    end
  end

  def destroy
    jukebox = Jukebox.where(id: params[:id], user: current_user).first
    if jukebox.blank?
      flash[:notice] = 'Jukebox nicht gefunden. Bitte probieren Sie es erneut.'
    else
      jukebox = Jukebox.find(params[:id])
      jukebox.destroy
      flash[:notice] = 'Jukebox gelöscht.'
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

  def queue
    jukebox = Jukebox.find(params[:jukebox_id])

    render json: jukebox.queued_songs.to_json(include: :song)
  end

  def add_song
    jukebox = Jukebox.find(params[:jukebox_id])
    song = Song.find(params[:song_id])

    # TODO: Remove this check once the queue is implemented
    if song.playing || jukebox.queued_songs.last.try(&:song_uri) == song.uri
      head :forbidden
    else
      SpotifyConnector.add_song_to_queue(jukebox, song)
      queued_songs = [songs: JSON.parse(jukebox.queued_songs.to_json(include: [:song]))]
      credits = [credits: { amount: jukebox.credit }]
      render json: (queued_songs + credits).to_json
    end
  end

  def playing_song
    jukebox = Jukebox.find(params[:jukebox_id])

    currently_playing_song = fetch_playing_song(jukebox.user)
    jukebox_song = Song.find_by_uri(currently_playing_song[:uri])
    updated = false
    if jukebox_song && jukebox_song.playing != true
      jukebox.songs.where(playing: true).each { |song| song.update_attribute(:playing, false) }
      jukebox_song.update_attribute(:playing, true)
      updated = updated_queue(jukebox, jukebox_song)
    end
    render json: { currently_playing_song:, queue_update: updated }
  end

  def next_song
    jukebox = Jukebox.find(params[:jukebox_id])
    play_next_song(jukebox.user)

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

  def updated_queue(jukebox, jukebox_song)
    return false unless jukebox.queued_songs.first.present?

    return false unless jukebox.queued_songs.first.song.uri == jukebox_song.uri

    jukebox.queued_songs.first.destroy
    true
  end

  def jukebox_params
    params.require(:jukebox).permit(:name, :user_id, :device_id, :playlist_id, :camera_id, images: [])
  end

  def fetch_active_devices(user)
    SpotifyConnector.fetch_active_devices(user)
  end

  def fetch_playlists(user)
    SpotifyConnector.fetch_playlists(user)
  end

  def fetch_playing_song(user)
    SpotifyConnector.fetch_playing_song(user)
  end

  def fetch_songs(jukebox)
    SpotifyConnector.fetch_songs(jukebox)
  end

  def play_next_song(user)
    SpotifyConnector.play_next_song(user)
  end
end
