module Api
  module V1
    class PostsController < Api::BaseController
      PER_PAGE = 10

      before_action :set_post, only: %i[show update destroy publish]

      def index
        posts = Post.all
        if params[:status].present? && Post.statuses.key?(params[:status])
          posts = posts.where(status: params[:status])
        end
        posts = posts.joins(:tags).where(tags: { slug: params[:tag] }) if params[:tag].present?
        if params[:search].present?
          posts = posts.where("title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%")
        end

        total_count = posts.distinct.count
        page = [ params.fetch(:page, 1).to_i, 1 ].max
        posts = posts.distinct.recent.offset((page - 1) * PER_PAGE).limit(PER_PAGE).includes(:tags)

        render json: {
          posts: posts.map { |post| post_summary_json(post) },
          meta: { total_count: total_count }
        }
      end

      def show
        render json: post_detail_json(@post)
      end

      def create
        @post = Post.new(post_params)
        set_published_at_if_needed

        if @post.save
          @post.reload
          render json: post_detail_json(@post), status: :created
        else
          render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        @post.assign_attributes(post_params)
        set_published_at_if_needed

        if @post.save
          @post.reload
          render json: post_detail_json(@post)
        else
          render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @post.destroy
        head :no_content
      end

      def publish
        if @post.published?
          render json: { error: "Post is already published" }, status: :unprocessable_entity
          return
        end

        @post.assign_attributes(status: :published, published_at: Time.current)
        if @post.save
          @post.reload
          render json: post_detail_json(@post)
        else
          render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_post
        @post = Post.includes(:tags, :comments).find_by!(slug: params[:slug])
      end

      def post_params
        params.require(:post).permit(:title, :excerpt, :body_markdown, :status, :published_at, tag_ids: [])
      end

      def set_published_at_if_needed
        if @post.published? && @post.published_at.blank?
          @post.published_at = Time.current
        end
      end

      def post_summary_json(post)
        {
          id: post.id,
          title: post.title,
          slug: post.slug,
          excerpt: post.excerpt,
          status: post.status,
          published_at: post.published_at&.iso8601(3),
          reading_time: post.reading_time,
          tags: post.tags.map(&:name),
          created_at: post.created_at.iso8601(3),
          updated_at: post.updated_at.iso8601(3)
        }
      end

      def post_detail_json(post)
        {
          id: post.id,
          title: post.title,
          slug: post.slug,
          excerpt: post.excerpt,
          body_markdown: post.body_markdown,
          rendered_body: post.rendered_body_highlighted,
          status: post.status,
          published_at: post.published_at&.iso8601(3),
          reading_time: post.reading_time,
          tags: post.tags.map { |t| { id: t.id, name: t.name, slug: t.slug } },
          comments: post.comments.recent.map { |c|
            {
              id: c.id,
              author_name: c.author_name,
              body: c.body,
              status: c.status,
              created_at: c.created_at.iso8601(3)
            }
          },
          created_at: post.created_at.iso8601(3),
          updated_at: post.updated_at.iso8601(3)
        }
      end
    end
  end
end
