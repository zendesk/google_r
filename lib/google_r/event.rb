require 'ostruct'

class GoogleR::Event
  attr_accessor :google_id, :etag, :start_time, :end_time, :calendar, :description, :summary,
    :visibility, :updated, :created, :status, :start_time_zone, :end_time_zone

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

  def self.path(calendar_google_id)
    "/calendar/v3/calendars/#{calendar_google_id}/events"
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
      event.status = json["status"]

      start_time = json["start"]["dateTime"] || json["start"]["date"]
      if start_time
        event.start_time = Time.parse(start_time)
        event.start_time_zone = json["start"]["timeZone"]
      end

      end_time = json["end"]["dateTime"] || json["end"]["date"]
      if end_time
        event.end_time = Time.parse(end_time)
        event.end_time_zone = json["end"]["timeZone"]
      end

      event.updated = Time.parse(json["updated"])
      event.created = Time.parse(json["created"])
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
    start = {}
    start["dateTime"] = format_time(start_time) if start_time
    start["date"] = nil if start_time
    start["timeZone"] = start_time_zone if start_time_zone
    finish = {}
    finish["dateTime"] = format_time(end_time) if end_time
    finish["date"] = nil if end_time
    finish["timeZone"] = end_time_zone if end_time_zone
    hash["start"] = start
    hash["end"] = finish
    hash["visibility"] = visibility if visibility
    hash["status"] = status if status
    Yajl::Encoder.encode(hash, yajl_opts)
  end

  def new?
    self.google_id.nil?
  end

  def format_time(time)
    time.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end
end
