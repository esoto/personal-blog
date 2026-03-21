class AddBodyMarkdownToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :body_markdown, :text
  end
end
