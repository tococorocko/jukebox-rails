class CreateQueuedSongs < ActiveRecord::Migration[6.0]
  def change
    create_table :queued_songs do |t|
      t.belongs_to :jukebox
      t.belongs_to :song
      t.string :song_uri
      t.timestamps
    end
  end
end
