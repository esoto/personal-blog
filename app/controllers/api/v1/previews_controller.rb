module Api
  module V1
    class PreviewsController < Api::BaseController
      def create
        markdown = params[:markdown]

        if markdown.blank?
          render json: { error: "Markdown content is required" }, status: :unprocessable_entity
          return
        end

        html = MarkdownRenderer.render_with_highlighting(markdown)
        render json: { html: html }
      end
    end
  end
end
