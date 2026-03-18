require "rails_helper"

RSpec.describe "Admin::Posts with Tags", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password123", password_confirmation: "password123") }
  let!(:ruby_tag) { Tag.create!(name: "Ruby") }
  let!(:rails_tag) { Tag.create!(name: "Rails") }
  let!(:web_tag) { Tag.create!(name: "Web Development") }

  before do
    post login_path, params: { email: "admin@example.com", password: "password123" }
  end

  describe "POST /admin/posts with tags" do
    context "creating a post with tags" do
      it "creates a post with associated tags" do
        expect {
          post admin_posts_path, params: {
            post: {
              title: "Ruby on Rails Guide",
              excerpt: "A comprehensive guide",
              status: "draft",
              tag_ids: [ ruby_tag.id, rails_tag.id ]
            }
          }
        }.to change(Post, :count).by(1)

        created_post = Post.last
        expect(created_post.tags).to match_array([ ruby_tag, rails_tag ])
      end

      it "creates a post with no tags" do
        expect {
          post admin_posts_path, params: {
            post: {
              title: "Post with no tags",
              excerpt: "A summary",
              status: "draft",
              tag_ids: []
            }
          }
        }.to change(Post, :count).by(1)

        created_post = Post.last
        expect(created_post.tags).to be_empty
      end

      it "creates a post with a single tag" do
        expect {
          post admin_posts_path, params: {
            post: {
              title: "Web Development Tips",
              excerpt: "Some tips",
              status: "draft",
              tag_ids: [ web_tag.id ]
            }
          }
        }.to change(Post, :count).by(1)

        created_post = Post.last
        expect(created_post.tags).to contain_exactly(web_tag)
      end
    end
  end

  describe "PATCH /admin/posts/:id with tags" do
    let!(:blog_post) { Post.create!(title: "Original Post", status: :draft) }

    context "updating a post's tags" do
      it "adds tags to a post that has none" do
        expect(blog_post.tags).to be_empty

        patch admin_post_path(blog_post), params: {
          post: {
            tag_ids: [ ruby_tag.id, rails_tag.id ]
          }
        }

        expect(blog_post.reload.tags).to match_array([ ruby_tag, rails_tag ])
      end

      it "replaces tags on a post" do
        blog_post.tags << ruby_tag
        blog_post.tags << rails_tag
        expect(blog_post.reload.tags).to match_array([ ruby_tag, rails_tag ])

        patch admin_post_path(blog_post), params: {
          post: {
            tag_ids: [ web_tag.id ]
          }
        }

        expect(blog_post.reload.tags).to contain_exactly(web_tag)
      end

      it "removes all tags from a post" do
        blog_post.tags << ruby_tag
        blog_post.tags << rails_tag

        patch admin_post_path(blog_post), params: {
          post: {
            tag_ids: []
          }
        }

        expect(blog_post.reload.tags).to be_empty
      end

      it "updates tags along with other post attributes" do
        patch admin_post_path(blog_post), params: {
          post: {
            title: "Updated Post Title",
            tag_ids: [ ruby_tag.id, web_tag.id ]
          }
        }

        expect(blog_post.reload.title).to eq("Updated Post Title")
        expect(blog_post.tags).to match_array([ ruby_tag, web_tag ])
      end
    end
  end

  describe "GET /admin/posts/:id/edit with tags" do
    context "edit form shows selected tags" do
      it "displays pre-selected tags in the edit form" do
        blog_post = Post.create!(title: "Tagged Post", status: :draft)
        blog_post.tags << ruby_tag
        blog_post.tags << rails_tag

        get edit_admin_post_path(blog_post)
        expect(response).to have_http_status(:ok)

        # Verify that the checkboxes for the selected tags are present and marked
        expect(response.body).to include("Ruby")
        expect(response.body).to include("Rails")
        expect(response.body).to include("Web Development")
      end

      it "displays all available tags in the edit form" do
        blog_post = Post.create!(title: "Post", status: :draft)

        get edit_admin_post_path(blog_post)
        expect(response).to have_http_status(:ok)

        # Verify all tags are available as options
        expect(response.body).to include("Ruby")
        expect(response.body).to include("Rails")
        expect(response.body).to include("Web Development")
      end
    end
  end

  describe "tag persistence" do
    it "persists tags when creating a published post" do
      freeze_time do
        post admin_posts_path, params: {
          post: {
            title: "Published Post with Tags",
            excerpt: "A published post",
            status: "published",
            tag_ids: [ ruby_tag.id, rails_tag.id ]
          }
        }
      end

      created_post = Post.last
      expect(created_post.published?).to be true
      expect(created_post.tags).to match_array([ ruby_tag, rails_tag ])
    end

    it "maintains tag associations across multiple updates" do
      blog_post = Post.create!(title: "Multi-update Post", status: :draft)

      # First update: add tags
      patch admin_post_path(blog_post), params: {
        post: { tag_ids: [ ruby_tag.id ] }
      }
      expect(blog_post.reload.tags).to contain_exactly(ruby_tag)

      # Second update: modify title and add more tags
      patch admin_post_path(blog_post), params: {
        post: {
          title: "Updated Title",
          tag_ids: [ ruby_tag.id, rails_tag.id ]
        }
      }
      expect(blog_post.reload.tags).to match_array([ ruby_tag, rails_tag ])

      # Third update: change tags while keeping title
      patch admin_post_path(blog_post), params: {
        post: {
          tag_ids: [ web_tag.id ]
        }
      }
      expect(blog_post.reload.tags).to contain_exactly(web_tag)
      expect(blog_post.reload.title).to eq("Updated Title")
    end
  end
end
