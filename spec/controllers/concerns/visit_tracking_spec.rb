require "rails_helper"

RSpec.describe VisitTracking, type: :controller do
  controller(ApplicationController) do
    def index
      render plain: "ok"
    end
  end

  describe "#excluded_path?" do
    it "excludes /admin paths" do
      expect(controller.send(:excluded_path?)).to be_falsey
    end
  end

  describe "#bot_request?" do
    it "returns false for normal user agents" do
      request.headers["HTTP_USER_AGENT"] = "Mozilla/5.0"
      expect(controller.send(:bot_request?)).to be false
    end

    it "returns true for bot user agents" do
      request.headers["HTTP_USER_AGENT"] = "Googlebot/2.1"
      expect(controller.send(:bot_request?)).to be true
    end

    it "handles nil user agent" do
      request.headers["HTTP_USER_AGENT"] = nil
      expect(controller.send(:bot_request?)).to be false
    end
  end
end
