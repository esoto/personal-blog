require "rails_helper"

RSpec.describe "Feeds", type: :request do
  describe "GET /feed.rss" do
    let!(:published_post) do
      Post.create!(
        title: "Published Post",
        status: :published,
        published_at: 1.day.ago,
        excerpt: "This is a published excerpt"
      )
    end

    let!(:older_published_post) do
      Post.create!(
        title: "Older Published Post",
        status: :published,
        published_at: 3.days.ago,
        excerpt: "This is an older excerpt"
      )
    end

    let!(:draft_post) do
      Post.create!(
        title: "Draft Post",
        status: :draft,
        excerpt: "This is a draft excerpt"
      )
    end

    it "returns a successful response" do
      get feed_path(format: :rss)
      expect(response).to have_http_status(:ok)
    end

    it "returns RSS content type" do
      get feed_path(format: :rss)
      expect(response.content_type).to include("application/rss+xml")
    end

    it "returns valid RSS 2.0 XML with channel metadata" do
      get feed_path(format: :rss)
      xml = Nokogiri::XML(response.body)

      expect(xml.at("rss")["version"]).to eq("2.0")
      expect(xml.at("channel title").text).to eq("Esteban Soto")
      expect(xml.at("channel description").text).to eq("Latest posts from Esteban Soto")
      expect(xml.at("channel link").text).to be_present
      expect(xml.at("channel language").text).to eq("en")
    end

    it "includes the XML declaration" do
      get feed_path(format: :rss)
      expect(response.body).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
    end

    it "includes an atom:link self-reference" do
      get feed_path(format: :rss)
      xml = Nokogiri::XML(response.body)
      atom_link = xml.at_xpath("//atom:link", "atom" => "http://www.w3.org/2005/Atom")

      expect(atom_link).to be_present
      expect(atom_link["rel"]).to eq("self")
      expect(atom_link["type"]).to eq("application/rss+xml")
    end

    it "includes lastBuildDate from the most recent post" do
      get feed_path(format: :rss)
      xml = Nokogiri::XML(response.body)

      expect(xml.at("channel lastBuildDate").text).to eq(published_post.published_at.rfc2822)
    end

    it "includes published posts" do
      get feed_path(format: :rss)

      expect(response.body).to include("Published Post")
      expect(response.body).to include("This is a published excerpt")
      expect(response.body).to include("Older Published Post")
      expect(response.body).to include("This is an older excerpt")
    end

    it "does not include draft posts" do
      get feed_path(format: :rss)

      expect(response.body).not_to include("Draft Post")
      expect(response.body).not_to include("This is a draft excerpt")
    end

    it "orders posts most recent first" do
      get feed_path(format: :rss)
      xml = Nokogiri::XML(response.body)
      items = xml.css("item title").map(&:text)

      expect(items).to eq([ "Published Post", "Older Published Post" ])
    end

    it "includes correct item elements for each post" do
      get feed_path(format: :rss)
      xml = Nokogiri::XML(response.body)
      item = xml.at("item")

      expect(item.at("title").text).to eq("Published Post")
      expect(item.at("description").text).to eq("This is a published excerpt")
      expect(item.at("pubDate").text).to eq(published_post.published_at.rfc2822)
      expect(item.at("link").text).to include("/posts/#{published_post.slug}")
      expect(item.at("guid").text).to include("/posts/#{published_post.slug}")
      expect(item.at("guid")["isPermaLink"]).to eq("true")
    end

    context "when there are no published posts" do
      before do
        Post.destroy_all
      end

      it "returns a successful response with empty channel" do
        get feed_path(format: :rss)
        expect(response).to have_http_status(:ok)
        xml = Nokogiri::XML(response.body)

        expect(xml.css("item")).to be_empty
        expect(xml.at("channel title").text).to eq("Esteban Soto")
      end
    end
  end

  describe "auto-discovery link" do
    it "includes RSS auto-discovery link tag in the HTML head" do
      get root_path
      expect(response.body).to include('application/rss+xml')
      expect(response.body).to include('Esteban Soto RSS Feed')
    end
  end
end
