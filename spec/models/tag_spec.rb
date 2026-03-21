require "rails_helper"

RSpec.describe Tag, type: :model do
  subject(:tag) { described_class.new(name: "Ruby") }

  describe "validations" do
    it "is valid with a name" do
      expect(tag).to be_valid
    end

    it "is invalid without a name" do
      tag.name = nil
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a duplicate name" do
      described_class.create!(name: "Ruby")
      duplicate = described_class.new(name: "Ruby")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "is invalid without a slug" do
      tag.name = nil
      tag.slug = nil
      expect(tag).not_to be_valid
      expect(tag.errors[:slug]).to include("can't be blank")
    end

    it "is invalid with a duplicate slug" do
      described_class.create!(name: "Ruby")
      duplicate = described_class.new(name: "Different Name")
      duplicate.slug = "ruby"
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end
  end

  describe "slug auto-generation" do
    it "generates a slug from the name on validation" do
      tag.validate
      expect(tag.slug).to eq("ruby")
    end

    it "parameterizes the name for the slug" do
      tag = described_class.new(name: "Ruby on Rails")
      tag.validate
      expect(tag.slug).to eq("ruby-on-rails")
    end

    it "does not overwrite a manually set slug" do
      tag = described_class.new(name: "Ruby", slug: "custom-slug")
      tag.validate
      expect(tag.slug).to eq("custom-slug")
    end

    it "generates a hex fallback when name parameterizes to blank" do
      tag = described_class.new(name: "!!!")
      tag.validate
      expect(tag.slug).to match(/\A\h{16}\z/)
    end

    it "handles slug collisions with hex suffix" do
      described_class.create!(name: "Ruby")
      tag = described_class.new(name: "Ruby!")
      tag.slug = nil
      tag.validate
      # "Ruby!" parameterizes to "ruby" which collides
      expect(tag.slug).to match(/\Aruby-\h+\z/)
    end
  end

  describe "associations" do
    it "has many post_tags" do
      expect(described_class.reflect_on_association(:post_tags).macro).to eq(:has_many)
    end

    it "has many posts through post_tags" do
      association = described_class.reflect_on_association(:posts)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:post_tags)
    end

    it "destroys associated post_tags when destroyed" do
      tag = described_class.create!(name: "Ruby")
      post = Post.create!(title: "Test Post", body_markdown: "# Content", status: :draft)
      tag.posts << post

      expect { tag.destroy }.to change(PostTag, :count).by(-1)
    end
  end
end
