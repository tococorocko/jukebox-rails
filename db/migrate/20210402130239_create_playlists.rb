class CreatePlaylists < ActiveRecord::Migration[6.0]
  def change
    create_table :playlists do |t|
      t.string :name
      t.string :playlist_uid
      t.string :uri
      t.integer :track_number
      t.belongs_to :user
      t.timestamps
    end
  end
end
