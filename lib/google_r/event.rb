require 'ostruct'

class GoogleR::Event
  attr_accessor :google_id, :etag, :start_time, :end_time, :calendar, :description, :summary,
                :visibility

  def initialize(calendar, opts = {})
    self.calendar = calendar
    self.visibility = opts[:visibility] || "private"
  end

  def self.url
    "https://www.googleapis.com"
  end

  def self.api_headers
    {
      'GData-Version' => '3.0',
      'Content-Type' => 'application/json',
    }
  end

  def path
    if new?
      "/calendar/v3/calendars/#{calendar.google_id}/events"
    else
      "/calendar/v3/calendars/#{calendar.google_id}/events/#{google_id}"
    end
  end

  def self.from_json(json, *attrs)
    calendar = attrs[0].calendar

    if json["kind"] == "calendar#events"
      (json["items"] || []).map { |e| from_json(e, *attrs) }
    elsif json["kind"] == "calendar#event"
      event = self.new(calendar)
      event.google_id = json["id"]
      event.etag = json["etag"]
      event.description = json["description"]
      event.summary = json["summary"]
      event.visibility = json["visibility"]
      event
    else
      raise "Not implemented:\n#{json.inspect}"
    end
  end

  def to_google(yajl_opts = {})
    hash = {
      "kind" => "calendar#event",
    }
    hash["etag"] = etag if etag
    hash["id"] = google_id if google_id
    hash["description"] = description if description
    hash["summary"] = summary if summary
    hash["start"] = {"dateTime" => start_time} if start_time
    hash["end"] = {"dateTime" => end_time} if end_time
    hash["visibility"] = visibility if visibility
    Yajl::Encoder.encode(hash, yajl_opts)
  end

  def new?
    self.google_id.nil?
  end
end
