require 'ostruct'

class GoogleR::Calendar
  attr_accessor :google_id, :etag, :summary, :description, :time_zone

  def self.url
    "https://www.googleapis.com"
  end

  def self.api_content_type
    :json
  end

  def self.api_headers
    {
      'GData-Version' => '3.0',
      'Content-Type' => 'application/json',
    }
  end

  def path
    if new?
      "/calendar/v3/calendars"
    else
      "/calendar/v3/calendars/#{google_id}"
    end
  end

  def self.from_json(json, *attrs)
    if json["kind"] == "calendar#calendar"
      calendar = self.new
      calendar.google_id = json["id"]
      calendar.etag = json["etag"]
      calendar.summary = json["summary"]
      calendar.description = json["description"]
      calendar.time_zone = json["timeZone"]
      calendar
    else
      raise "Not implemented:\n#{json.inspect}"
    end
  end

  def to_json(yajl_opts = {})
    hash = {
      "kind" => "calendar#calendar",
    }
    hash["etag"] = etag if etag
    hash["id"] = google_id if google_id
    hash["summary"] = summary if summary
    hash["description"] = description if description
    hash["timeZone"] = time_zone if time_zone
    Yajl::Encoder.encode(hash, yajl_opts)
  end

  def new?
    self.google_id.nil?
  end
end
