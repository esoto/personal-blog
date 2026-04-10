class AddMissingVisitIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :visits, :referrer
    add_index :visits, :browser
    add_index :visits, :path
  end
end
