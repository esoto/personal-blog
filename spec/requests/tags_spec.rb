require "rails_helper"

RSpec.describe "Tags", type: :request do
  describe "GET /tags/:slug" do
    let!(:tag) { Tag.create!(name: "Ruby") }

    context "with published posts" do
      let!(:published_post) do
        post = Post.create!(
          title: "Ruby Basics",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "Learn Ruby fundamentals"
        )
        post.tags << tag
        post
      end

      let!(:untagged_post) do
        Post.create!(
          title: "Untagged Post",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "This post has no tags"
        )
      end

      it "returns 200" do
        get tag_path(slug: tag.slug)
        expect(response).to have_http_status(:ok)
      end

      it "displays the tag name" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Ruby")
      end

      it "shows posts tagged with this tag" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Ruby Basics")
      end

      it "does not show untagged posts" do
        get tag_path(slug: tag.slug)
        expect(response.body).not_to include("Untagged Post")
      end

      it "sets the page title" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Posts tagged with Ruby")
      end
    end

    context "with draft posts" do
      let!(:draft_post) do
        post = Post.create!(
          title: "Draft Ruby Post",
          status: :draft,
          excerpt: "This is a draft"
        )
        post.tags << tag
        post
      end

      it "does not show draft posts" do
        get tag_path(slug: tag.slug)
        expect(response.body).not_to include("Draft Ruby Post")
      end
    end

    context "with future-dated posts" do
      let!(:future_post) do
        post = Post.create!(
          title: "Future Ruby Post",
          status: :published,
          published_at: 1.day.from_now,
          excerpt: "Coming soon"
        )
        post.tags << tag
        post
      end

      it "does not show future-dated posts" do
        get tag_path(slug: tag.slug)
        expect(response.body).not_to include("Future Ruby Post")
      end
    end

    context "with no published posts" do
      it "shows an empty state message" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("No published posts with this tag yet")
      end
    end

    context "with a non-existent tag" do
      it "returns 404" do
        get tag_path(slug: "nonexistent")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with multiple tags on posts" do
      let!(:other_tag) { Tag.create!(name: "Rails") }

      let!(:multi_tag_post) do
        post = Post.create!(
          title: "Ruby on Rails Guide",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "A guide to Rails"
        )
        post.tags << [tag, other_tag]
        post
      end

      it "shows the post when filtering by either tag" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Ruby on Rails Guide")

        get tag_path(slug: other_tag.slug)
        expect(response.body).to include("Ruby on Rails Guide")
      end

      it "displays the post count" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("1 post")
      end
    end
  end
end
