class CreateSongs < ActiveRecord::Migration[6.0]
  def change
    create_table :songs do |t|
      t.string :name
      t.string :artist
      t.string :uri
      t.string :cover_uri
      t.string :length
      t.boolean :playing, default: false
      t.belongs_to :jukebox
      t.timestamps
    end
  end
end
