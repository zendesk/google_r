require "google_r/version"

require "nokogiri"
require "faraday"
require "logger"

require "google_r/exceptions"
require "google_r/contact"
require "google_r/calendar"
require "google_r/event"
require "google_r/group"

class GoogleR
  attr_reader :oauth2_token
  attr_accessor :logger

  def initialize(oauth2_token)
    @oauth2_token = oauth2_token
    self.logger = Logger.new("/dev/null")
    self.logger.formatter = Logger::Formatter.new
  end

  def fetch(object)
    response = make_request(:get, object)
    if response.status == 200
      parse_response(response, object)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def save(contact)
    if contact.new?
      create(contact)
    else
      update(contact)
    end
  end

  def create(object)
    response = make_request(:post, object)
    if response.status == 200 || response.status == 201
      parse_response(response, object)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def update(object)
    response = make_request(:patch, object)
    if response.status == 200
      parse_response(response, object)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def contacts(params = {})
    fetch_objects(GoogleR::Contact, params)
  end

  def groups(params = {})
    fetch_objects(GoogleR::Group, params)
  end

  def calendars(params = {})
    fetch_objects(GoogleR::Calendar, params)
  end

  def events(calendar, params = {})
    fetch_events(calendar, params)
  end

  def fetch_events(calendar, params)
    event = GoogleR::Event.new(calendar)
    max_results = 1

    params.merge!({"maxResults" => max_results})

    events = []
    next_page_token = nil

    begin
      response = make_request(:get, event, params)
      #next_page_token = nil
      if response.status == 200
        events.concat(parse_response(response, event))
        next_page_token = Yajl::Parser.parse(response.body)["nextPageToken"]
        params.merge!({"pageToken" => next_page_token})
      else
        raise GoogleR::Error.new(response.status, response.body)
      end
    end while !next_page_token.nil?
    events
  end

  def fetch_objects(object_class, params = {})
    current_count = 0
    per_page = 500
    results = []
    start_index = 1
    connection = connection(object_class)
    begin
      query_params = {
        :"max-results" => per_page,
        :"start-index" => start_index,
      }.merge(params)

      response = connection.get(object_class.path + "?" + Faraday::Utils.build_query(query_params)) do |req|
        req.headers['Content-Type'] = 'application/atom+xml'
        req.headers['Authorization'] = "OAuth #{oauth2_token}"
        req.headers['GData-Version'] = '3.0'
      end
      if response.status == 200
        case response.headers["Content-Type"]
        when /json/
          entries = object_class.from_json(Yajl::Parser.parse(response.body))
        when /xml/
          entries = object_class.from_xml(Nokogiri::XML.parse(response.body))
        end
        current_count = entries.size
        next if current_count == 0
        results += entries
        start_index += current_count
      else
        raise GoogleR::Error.new(response.status, response.body)
      end
    end while current_count == per_page
    results
  end

  def connection(klass)
    Faraday.new(:url => klass.url, :ssl => {:verify => false})
  end

  def make_request(http_method, object, params = {})
    body = case object.class.api_content_type
           when :json
             object.to_json
           when :xml
             object.to_xml
           else
             raise "Cannot serialize object"
           end
    path = object.path + "?" + Faraday::Utils.build_query(params)
    response = connection(object.class).send(http_method, path) do |req|
      req.headers['Authorization'] = "OAuth #{oauth2_token}"
      object.class.api_headers.each do |header, value|
        req.headers[header] = value
      end
      req.body = body
      puts "making #{http_method} request to #{path}"
    end
  end

  def parse_response(response, object)
    case object.class.api_content_type
    when :json
      object.class.from_json(Yajl::Parser.parse(response.body), object)
    when :xml
      object.class.from_xml(Nokogiri::XML.parse(response.body), object)
    else
      raise "Cannot deserialize"
    end
  end
end
