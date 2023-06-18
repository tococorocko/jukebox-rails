class DropQueuedSongs < ActiveRecord::Migration[7.0]
  def up
    drop_table :queued_songs
  end

  def down
    create_table :queued_songs do |t|
      t.belongs_to :jukebox
      t.belongs_to :song
      t.string :song_uri
      t.timestamps
    end
  end
end
