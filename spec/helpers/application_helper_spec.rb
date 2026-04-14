require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_link_class" do
    # Asserting on semantic markers (font-semibold for active, hover: for
    # inactive) instead of literal Tailwind class strings keeps the spec
    # stable across palette/design-system changes. The `active vs inactive`
    # branch is the actual behavior under test.

    context "with exact match (default)" do
      it "returns active classes when current page matches the path" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(true)
        allow(helper.request).to receive(:path).and_return("/posts")

        result = helper.nav_link_class("/posts")
        expect(result).to include("font-semibold")
        expect(result).not_to include("hover:")
      end

      it "returns inactive classes when current page does not match the path" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(false)
        allow(helper.request).to receive(:path).and_return("/about")

        result = helper.nav_link_class("/posts")
        expect(result).to include("hover:")
        expect(result).not_to include("font-semibold")
      end

      it "does not match subpaths without prefix_match" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(false)
        allow(helper.request).to receive(:path).and_return("/posts/my-post")

        result = helper.nav_link_class("/posts")
        expect(result).to include("hover:")
        expect(result).not_to include("font-semibold")
      end
    end

    context "with prefix_match: true" do
      it "returns active classes when request path starts with the given path" do
        allow(helper.request).to receive(:path).and_return("/tags/ruby")

        result = helper.nav_link_class("/tags", prefix_match: true)
        expect(result).to include("font-semibold")
      end

      it "returns active classes for the exact path" do
        allow(helper.request).to receive(:path).and_return("/tags")

        result = helper.nav_link_class("/tags", prefix_match: true)
        expect(result).to include("font-semibold")
      end

      it "returns inactive classes when request path does not start with the given path" do
        allow(helper.request).to receive(:path).and_return("/posts")

        result = helper.nav_link_class("/tags", prefix_match: true)
        expect(result).to include("hover:")
        expect(result).not_to include("font-semibold")
      end

      it "matches nested admin paths" do
        allow(helper.request).to receive(:path).and_return("/admin/posts/42/edit")

        result = helper.nav_link_class("/admin/posts", prefix_match: true)
        expect(result).to include("font-semibold")
      end

      it "does not match partial path prefixes" do
        allow(helper.request).to receive(:path).and_return("/tagsomething")

        result = helper.nav_link_class("/tags", prefix_match: true)
        expect(result).to include("hover:")
        expect(result).not_to include("font-semibold")
      end
    end

    context "theme: defaults to :public (emerald accent)" do
      it "active state uses the emerald accent token" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(true)
        allow(helper.request).to receive(:path).and_return("/posts")

        expect(helper.nav_link_class("/posts")).to include("text-accent-green")
      end

      it "inactive state hovers to the emerald accent token" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(false)
        allow(helper.request).to receive(:path).and_return("/about")

        expect(helper.nav_link_class("/posts")).to include("hover:text-accent-green")
      end
    end

    context "theme: :admin (blue accent retained)" do
      it "active state uses the blue accent token" do
        allow(helper).to receive(:current_page?).with("/admin").and_return(true)
        allow(helper.request).to receive(:path).and_return("/admin")

        result = helper.nav_link_class("/admin", theme: :admin)
        expect(result).to include("text-accent-blue")
        expect(result).to include("font-semibold")
      end

      it "inactive state hovers to the blue accent token" do
        allow(helper).to receive(:current_page?).with("/admin").and_return(false)
        allow(helper.request).to receive(:path).and_return("/admin/posts")

        result = helper.nav_link_class("/admin", theme: :admin)
        expect(result).to include("hover:text-accent-blue")
        expect(result).not_to include("font-semibold")
      end

      it "honors prefix_match: true" do
        allow(helper.request).to receive(:path).and_return("/admin/comments/42")

        result = helper.nav_link_class("/admin/comments", prefix_match: true, theme: :admin)
        expect(result).to include("text-accent-blue")
        expect(result).to include("font-semibold")
      end
    end

    context "snapshot — exact class strings (catches regressions in the helper output format)" do
      it "active public" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(true)
        allow(helper.request).to receive(:path).and_return("/posts")
        expect(helper.nav_link_class("/posts")).to eq("text-accent-green font-semibold transition-fast")
      end

      it "inactive public" do
        allow(helper).to receive(:current_page?).with("/posts").and_return(false)
        allow(helper.request).to receive(:path).and_return("/about")
        expect(helper.nav_link_class("/posts")).to eq("text-text-secondary hover:text-accent-green transition-fast")
      end

      it "active admin" do
        allow(helper).to receive(:current_page?).with("/admin").and_return(true)
        allow(helper.request).to receive(:path).and_return("/admin")
        expect(helper.nav_link_class("/admin", theme: :admin)).to eq("text-accent-blue font-semibold transition-fast")
      end

      it "inactive admin" do
        allow(helper).to receive(:current_page?).with("/admin").and_return(false)
        allow(helper.request).to receive(:path).and_return("/admin/posts")
        expect(helper.nav_link_class("/admin", theme: :admin)).to eq("text-text-secondary hover:text-accent-blue transition-fast")
      end
    end
  end
end
