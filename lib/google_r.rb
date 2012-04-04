require "google_r/version"

require "nokogiri"
require "yajl"
require "faraday"
require "logger"

require "google_r/exceptions"
require "google_r/contact"
require "google_r/calendar"
require "google_r/event"
require "google_r/group"
require "google_r/token"

class GoogleR
  attr_reader :oauth2_token
  attr_accessor :logger

  def initialize(oauth2_token)
    @oauth2_token = oauth2_token
    self.logger = Logger.new("/dev/null")
    self.logger.formatter = Logger::Formatter.new
  end

  def fetch(object, params = {})
    response = make_request(:get, object.class.url, object.path, params, nil, object.class.api_headers)
    if response.status == 200
      parse_response(response, object)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def save(object)
    if object.new?
      create(object)
    else
      update(object)
    end
  end

  def create(object, params = {})
    response = make_request(:post, object.class.url, object.path, params, object.to_google, object.class.api_headers)
    if response.status == 200 || response.status == 201
      parse_response(response, object)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def update(object)
    response = make_request(:patch, object.class.url, object.path, params, object.to_google, object.class.api_headers)
    if response.status == 200
      parse_response(response, object)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def contacts(params = {})
    fetch_legacy_xml(GoogleR::Contact, GoogleR::Contact.url, GoogleR::Contact.path, params)
  end

  def groups(params = {})
    fetch_legacy_xml(GoogleR::Group, GoogleR::Group.url, GoogleR::Group.path, params)
  end

  def events(calendar, params = {})
    fetch_events(calendar, params)
  end

  def fetch_events(calendar, params)
    max_results = 500

    params.merge!({"maxResults" => max_results})

    events = []
    next_page_token = nil

    begin
      event = GoogleR::Event.new(calendar)
      response = make_request(:get, GoogleR::Event.url, GoogleR::Event.path(calendar.google_id), params, nil, GoogleR::Event.api_headers)
      # def make_request(http_method, url, path, params, body, headers)
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

  def fetch_legacy_xml(klass, url, path, params = {})
    current_count = 0
    per_page = 500
    results = []
    start_index = 1
    connection = connection(url)
    begin
      query_params = params.merge({
        :"max-results" => per_page,
        :"start-index" => start_index,
      })

      response = connection.get(path + "?" + Faraday::Utils.build_query(query_params)) do |req|
        req.headers['Content-Type'] = 'application/atom+xml'
        req.headers['Authorization'] = "OAuth #{oauth2_token}"
        req.headers['GData-Version'] = '3.0'
      end
      if response.status == 200
        case response.headers["Content-Type"]
        when /xml/
          entries = parse_legacy_xml_response(response.body, klass)
        else
          raise "Not implemented"
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

  def parse_legacy_xml_response(body, klass)
    doc = Nokogiri::XML.parse(body)
    doc.remove_namespaces!
    klass.from_xml(doc)
  end

  def connection(url)
    Faraday.new(:url => url, :ssl => {:verify => false})
  end

  def make_request(http_method, url, path, params, body, headers)
    params = Faraday::Utils.build_query(params)
    path = path + "?" + params unless params == ""
    response = connection(url).send(http_method, path) do |req|
      req.headers['Authorization'] = "OAuth #{oauth2_token}"
      headers.each do |header, value|
        req.headers[header] = value
      end
      req.body = body
      puts "#{http_method} #{url}/#{path}"
    end
  end

  def parse_response(response, object)
    case response.headers["Content-Type"]
    when /json/
      object.class.from_json(Yajl::Parser.parse(response.body), object)
    when /xml/
      doc = Nokogiri::XML.parse(response.body)
      doc.remove_namespaces!
      object.class.from_xml(doc.root, object)
    else
      raise "Cannot deserialize"
    end
  end

  def token
    begin
      token = GoogleR::Token.new(oauth2_token)
      response = make_request(:post, GoogleR::Token.url, token.path, {:access_token => oauth2_token}, nil, GoogleR::Token.headers)
      if response.status == 200
        GoogleR::Token.from_json(Yajl::Parser.parse(response.body), oauth2_token)
      else
        nil
      end
    end
  end
end
