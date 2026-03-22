class TagsController < ApplicationController
  def index
    published_status = Post.statuses[:published]
    @tags = Tag
      .joins(Tag.sanitize_sql_array([
        "LEFT JOIN post_tags ON post_tags.tag_id = tags.id
         LEFT JOIN posts ON posts.id = post_tags.post_id
           AND posts.status = ?
           AND posts.published_at <= NOW()", published_status
      ]))
      .group("tags.id")
      .select("tags.*, COUNT(posts.id) AS posts_count")
      .order(:name)
  end

  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts.published.recent.includes(:tags)
  end
end
