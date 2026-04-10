module Admin
  class VisitsController < BaseController
    def index
      @total_visits = Visit.count
      @today_visits = Visit.today.count
      @week_visits = Visit.this_week.count
      @month_visits = Visit.this_month.count
      @visits = Visit.order(created_at: :desc).page(params[:page]).per(25)
      @top_referrers = Visit.top_referrers(5)
      @top_locations = Visit.top_locations(5)
      @top_browsers = Visit.top_browsers(5)
    end
  end
end
