class TagsController < ApplicationController
  def index
    @tags = Tag
      .joins("LEFT JOIN post_tags ON post_tags.tag_id = tags.id
              LEFT JOIN posts ON posts.id = post_tags.post_id
                AND posts.status = #{Post.statuses[:published]}
                AND posts.published_at <= NOW()")
      .group("tags.id")
      .select("tags.*, COUNT(posts.id) AS posts_count")
      .order(:name)
  end

  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts.published.recent.includes(:tags).with_rich_text_body
  end
end
