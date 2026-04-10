class Visit < ApplicationRecord
  validates :ip_address, presence: true
  validates :path, presence: true

  geocoded_by :ip_address
  after_create_commit :geocode_later

  scope :today, -> { where(created_at: Time.current.beginning_of_day..) }
  scope :this_week, -> { where(created_at: 7.days.ago..) }
  scope :this_month, -> { where(created_at: 30.days.ago..) }

  def self.top_referrers(limit = 10)
    where.not(referrer: [ nil, "" ])
         .group(:referrer)
         .order("count_all DESC")
         .limit(limit)
         .count
         .to_a
  end

  def self.top_locations(limit = 10)
    where.not(city: [ nil, "" ])
         .group("city || COALESCE(', ' || NULLIF(country, ''), '')")
         .order("count_all DESC")
         .limit(limit)
         .count
         .to_a
  end

  def self.top_browsers(limit = 10)
    where.not(browser: [ nil, "" ])
         .group(:browser)
         .order("count_all DESC")
         .limit(limit)
         .count
         .to_a
  end

  def self.create_from_request(request)
    ua = UserAgentParser.parse(request.user_agent)
    device_type = if request.user_agent&.match?(/Mobile/i)
                    "Mobile"
    elsif request.user_agent&.match?(/Tablet/i)
                    "Tablet"
    else
                    "Desktop"
    end

    create(
      ip_address: request.remote_ip,
      path: request.path,
      referrer: request.referrer,
      user_agent: request.user_agent,
      browser: ua.name,
      device_type: device_type,
      os: ua.os.name
    )
  end

  private

  def geocode_later
    GeocodeVisitJob.perform_later(id) if latitude.blank?
  end
end
