module Admin
  class BaseController < ApplicationController
    include Authentication
    layout "admin"

    skip_after_action :track_visit
  end
end
