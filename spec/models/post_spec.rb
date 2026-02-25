require "rails_helper"

RSpec.describe Post, type: :model do
  subject(:post) { described_class.new(title: "My First Post", status: :draft) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(post).to be_valid
    end

    it "is invalid without a title" do
      post.title = nil
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a slug when auto-generation fails" do
      post.title = nil
      post.slug = nil
      expect(post).not_to be_valid
      expect(post.errors[:slug]).to include("can't be blank")
    end

    it "is invalid with a duplicate slug" do
      described_class.create!(title: "My First Post", status: :draft)
      duplicate = described_class.new(title: "My First Post", status: :draft)
      # The second post should get a unique slug via suffix, so let's force the same slug
      duplicate.slug = "my-first-post"
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end
  end

  describe "status enum" do
    it "defaults to draft" do
      new_post = described_class.new(title: "Draft Post")
      expect(new_post).to be_draft
    end

    it "can be set to published" do
      post.status = :published
      expect(post).to be_published
    end

    it "defines draft as 0 and published as 1" do
      expect(described_class.statuses).to eq("draft" => 0, "published" => 1)
    end
  end

  describe "slug auto-generation" do
    it "generates a slug from the title on validation" do
      post = described_class.new(title: "Hello World")
      post.validate
      expect(post.slug).to eq("hello-world")
    end

    it "parameterizes the title for the slug" do
      post = described_class.new(title: "This Is a Complex Title! With Punctuation?")
      post.validate
      expect(post.slug).to eq("this-is-a-complex-title-with-punctuation")
    end

    it "does not overwrite a manually set slug" do
      post = described_class.new(title: "Hello World", slug: "custom-slug")
      post.validate
      expect(post.slug).to eq("custom-slug")
    end

    it "generates a random slug when title parameterizes to blank" do
      post = described_class.new(title: "!!!???")
      post.validate
      expect(post.slug).to match(/\A\h{16}\z/)
    end

    it "does not regenerate slug on update if title changes" do
      post = described_class.create!(title: "Original Title", status: :draft)
      original_slug = post.slug
      post.update!(title: "Updated Title")
      expect(post.slug).to eq(original_slug)
    end
  end

  describe "slug uniqueness with suffix" do
    it "appends a hex suffix when slug already exists" do
      described_class.create!(title: "Duplicate Title", status: :draft)
      second_post = described_class.create!(title: "Duplicate Title", status: :draft)
      expect(second_post.slug).to match(/\Aduplicate-title-\h+\z/)
    end

    it "generates unique slugs for multiple posts with the same title" do
      first = described_class.create!(title: "Same Title", status: :draft)
      second = described_class.create!(title: "Same Title", status: :draft)
      third = described_class.create!(title: "Same Title", status: :draft)

      slugs = [ first.slug, second.slug, third.slug ]
      expect(slugs.uniq.length).to eq(3)
    end
  end

  describe "scopes" do
    let!(:published_post) do
      described_class.create!(
        title: "Published Post",
        status: :published,
        published_at: 1.day.ago
      )
    end

    let!(:future_published_post) do
      described_class.create!(
        title: "Future Published Post",
        status: :published,
        published_at: 1.day.from_now
      )
    end

    let!(:draft_post) do
      described_class.create!(
        title: "Draft Post",
        status: :draft
      )
    end

    describe ".published" do
      it "returns only published posts with published_at in the past or present" do
        expect(described_class.published).to include(published_post)
        expect(described_class.published).not_to include(future_published_post)
        expect(described_class.published).not_to include(draft_post)
      end
    end

    describe ".drafts" do
      it "returns only draft posts" do
        expect(described_class.drafts).to include(draft_post)
        expect(described_class.drafts).not_to include(published_post)
        expect(described_class.drafts).not_to include(future_published_post)
      end
    end

    describe ".recent" do
      it "orders posts by published_at descending" do
        results = described_class.recent
        published_posts = results.select { |p| p.published_at.present? }
        expect(published_posts).to eq(published_posts.sort_by(&:published_at).reverse)
      end

      it "places posts with NULL published_at last" do
        results = described_class.recent
        published_at_values = results.map(&:published_at)
        non_nil = published_at_values.compact
        nil_count = published_at_values.count(&:nil?)

        expect(published_at_values.last(nil_count)).to all(be_nil)
        expect(non_nil.length + nil_count).to eq(published_at_values.length)
      end
    end
  end

  describe "has_rich_text :body" do
    it "responds to body" do
      expect(post).to respond_to(:body)
    end

    it "responds to body=" do
      expect(post).to respond_to(:body=)
    end

    it "can set and retrieve rich text body" do
      post.save!
      post.body = "<h1>Rich text content</h1>"
      post.save!
      post.reload
      expect(post.body.to_plain_text).to include("Rich text content")
    end
  end
end
