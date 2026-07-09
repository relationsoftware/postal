# frozen_string_literal: true

class CreateAdminAPIKeys < ActiveRecord::Migration[7.1]

  def change
    create_table :admin_api_keys do |t|
      t.string :name
      t.string :key
      t.integer :user_id
      t.datetime :last_used_at
      t.string :uuid

      t.timestamps
    end
    add_index :admin_api_keys, :user_id
    add_index :admin_api_keys, :uuid
  end

end
