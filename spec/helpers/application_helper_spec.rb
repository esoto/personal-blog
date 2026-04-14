require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_link_class" do
    let(:active_classes) { "text-accent-green font-semibold transition-fast" }
    let(:inactive_classes) { "text-text-secondary hover:text-accent-green transition-fast" }

    context "with exact match (default)" do
      it "returns active classes when current page matches the path" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(true)
        allow(helper.request).to receive(:path).and_return("/posts")

        expect(helper.nav_link_class("/posts")).to eq(active_classes)
      end

      it "returns inactive classes when current page does not match the path" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(false)
        allow(helper.request).to receive(:path).and_return("/about")

        expect(helper.nav_link_class("/posts")).to eq(inactive_classes)
      end

      it "does not match subpaths without prefix_match" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(false)
        allow(helper.request).to receive(:path).and_return("/posts/my-post")

        expect(helper.nav_link_class("/posts")).to eq(inactive_classes)
      end
    end

    context "with prefix_match: true" do
      it "returns active classes when request path starts with the given path" do
        allow(helper.request).to receive(:path).and_return("/tags/ruby")

        expect(helper.nav_link_class("/tags", prefix_match: true)).to eq(active_classes)
      end

      it "returns active classes for the exact path" do
        allow(helper.request).to receive(:path).and_return("/tags")

        expect(helper.nav_link_class("/tags", prefix_match: true)).to eq(active_classes)
      end

      it "returns inactive classes when request path does not start with the given path" do
        allow(helper.request).to receive(:path).and_return("/posts")

        expect(helper.nav_link_class("/tags", prefix_match: true)).to eq(inactive_classes)
      end

      it "matches nested admin paths" do
        allow(helper.request).to receive(:path).and_return("/admin/posts/42/edit")

        expect(helper.nav_link_class("/admin/posts", prefix_match: true)).to eq(active_classes)
      end

      it "does not match partial path prefixes" do
        allow(helper.request).to receive(:path).and_return("/tagsomething")

        expect(helper.nav_link_class("/tags", prefix_match: true)).to eq(inactive_classes)
      end
    end

    context "admin navigation paths" do
      it "returns active classes for admin dashboard on exact match" do
        allow(helper).to receive(:current_page?).with("/admin").and_return(true)
        allow(helper.request).to receive(:path).and_return("/admin")

        expect(helper.nav_link_class("/admin")).to eq(active_classes)
      end

      it "returns inactive classes for admin dashboard when on another admin page" do
        allow(helper).to receive(:current_page?).with("/admin").and_return(false)
        allow(helper.request).to receive(:path).and_return("/admin/posts")

        expect(helper.nav_link_class("/admin")).to eq(inactive_classes)
      end

      it "returns active classes for admin comments with prefix match" do
        allow(helper.request).to receive(:path).and_return("/admin/comments")

        expect(helper.nav_link_class("/admin/comments", prefix_match: true)).to eq(active_classes)
      end
    end
  end
end
