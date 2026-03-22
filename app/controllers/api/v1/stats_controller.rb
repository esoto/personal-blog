module Api
  module V1
    class StatsController < Api::BaseController
      def index
        render json: {
          total_posts: Post.count,
          published_posts: Post.published.count,
          draft_posts: Post.drafts.count,
          pending_comments: Comment.pending.count,
          total_tags: Tag.count
        }
      end
    end
  end
end
