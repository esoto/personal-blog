module Admin
  class TagsController < BaseController
    before_action :set_tag, only: %i[edit update destroy]

    def index
      @tags = Tag.left_joins(:post_tags)
                 .select("tags.*, COUNT(post_tags.id) AS posts_count")
                 .group("tags.id")
                 .order(:name)
    end

    def new
      @tag = Tag.new
    end

    def create
      @tag = Tag.new(tag_params)

      if @tag.save
        redirect_to admin_tags_path, notice: "Tag was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: "Tag was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy
      redirect_to admin_tags_path, notice: "Tag was successfully deleted."
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
