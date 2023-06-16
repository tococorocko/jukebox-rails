# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :name, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :provider, null: false, default: ""
      t.string :uid, null: false, default: ""
      t.string :access_token, null: false, default: ""
      t.string :refresh_token, null: false, default: ""

      t.timestamps null: false
    end

    add_index :users, :name, unique: true
  end
end
