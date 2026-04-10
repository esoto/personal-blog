class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.string :ip_address, null: false
      t.string :path, null: false
      t.string :referrer
      t.text :user_agent
      t.string :browser
      t.string :device_type
      t.string :os
      t.string :country
      t.string :city
      t.float :latitude
      t.float :longitude

      t.timestamps
    end

    add_index :visits, :created_at
    add_index :visits, :ip_address
    add_index :visits, :country
  end
end
