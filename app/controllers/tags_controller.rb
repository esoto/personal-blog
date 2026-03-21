class TagsController < ApplicationController
  def index
    @tags = Tag.left_joins(:posts)
               .group(:id)
               .select("tags.*, COUNT(posts.id) AS posts_count")
               .order(:name)
  end

  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts.published.recent.includes(:tags)
  end
end
