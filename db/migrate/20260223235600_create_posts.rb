class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.datetime :published_at
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :posts, :slug, unique: true
  end
end
