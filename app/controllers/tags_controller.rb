class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts.published.recent.includes(:tags)
  end
end
