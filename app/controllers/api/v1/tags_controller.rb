module Api
  module V1
    class TagsController < Api::BaseController
      before_action :set_tag, only: %i[update destroy]

      def index
        tags = Tag.left_joins(:post_tags)
                   .select("tags.*, COUNT(post_tags.id) AS posts_count")
                   .group("tags.id")
                   .order(:name)

        render json: tags.map { |tag| tag_json(tag) }
      end

      def create
        tag = Tag.new(tag_params)

        if tag.save
          render json: tag_json(tag), status: :created
        else
          render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @tag.update(tag_params)
          render json: tag_json(@tag)
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @tag.destroy
        head :no_content
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:name)
      end

      def tag_json(tag)
        {
          id: tag.id,
          name: tag.name,
          slug: tag.slug,
          posts_count: tag.has_attribute?(:posts_count) ? tag.posts_count : tag.posts.count,
          created_at: tag.created_at.iso8601(3),
          updated_at: tag.updated_at.iso8601(3)
        }
      end
    end
  end
end
