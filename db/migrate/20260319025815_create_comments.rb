class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.string :author_name, null: false
      t.string :email, null: false
      t.text :body, null: false
      t.references :post, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :comments, :status
  end
end
