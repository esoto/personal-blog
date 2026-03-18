require "rails_helper"

RSpec.describe "Posts", type: :request do
  describe "GET /posts" do
    context "with published posts" do
      let!(:published_post) do
        Post.create!(
          title: "Published Post",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "This is a published post"
        )
      end

      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          status: :draft,
          excerpt: "This is a draft post"
        )
      end

      it "returns 200" do
        get posts_path
        expect(response).to have_http_status(:ok)
      end

      it "shows published posts" do
        get posts_path
        expect(response.body).to include("Published Post")
      end

      it "does not show draft posts" do
        get posts_path
        expect(response.body).not_to include("Draft Post")
      end
    end

    context "with pagination" do
      before do
        12.times do |i|
          Post.create!(
            title: "Article-#{format('%02d', i + 1)}",
            status: :published,
            published_at: (12 - i).days.ago,
            excerpt: "Excerpt #{i + 1}"
          )
        end
      end

      it "shows only 10 posts on page 1" do
        get posts_path
        # Newest first: Article-12, 11, ..., 03
        expect(response.body).to include("Article-12")
        expect(response.body).to include("Article-03")
        expect(response.body).not_to include("Article-02")
      end

      it "shows remaining posts on page 2" do
        get posts_path(page: 2)
        # Oldest 2: Article-02, Article-01
        expect(response.body).to include("Article-02")
        expect(response.body).to include("Article-01")
        expect(response.body).not_to include("Article-12")
      end
    end
  end

  describe "GET /posts/:slug" do
    context "with a published post" do
      let!(:post) do
        Post.create!(
          title: "Test Post",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "Test excerpt"
        )
      end

      it "returns 200" do
        get post_show_path(slug: post.slug)
        expect(response).to have_http_status(:ok)
      end

      it "displays the post title" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include("Test Post")
      end

      it "includes the clipboard Stimulus controller on the post body" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('data-controller="clipboard"')
      end
    end

    context "with a draft post" do
      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          status: :draft,
          excerpt: "Draft excerpt"
        )
      end

      it "returns 404" do
        get post_show_path(slug: draft_post.slug)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a non-existent slug" do
      it "returns 404" do
        get post_show_path(slug: "nonexistent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
