class CreateJukeboxes < ActiveRecord::Migration[6.0]
  def change
    create_table :jukeboxes do |t|
      t.string :name
      t.integer :credit, default: 0
      t.belongs_to :user
      t.belongs_to :device
      t.belongs_to :playlist
      t.timestamps
    end
  end
end
