require "google_r/version"

require "nokogiri"
require "faraday"
require "logger"

require "google_r/exceptions"
require "google_r/contact"
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
    remote_id = object.google_id.split("/").last
    path = "/m8/feeds/#{object.class.path_part}/default/full/#{remote_id}"
    response = connection.get(path) do |req|
      req.headers['Content-Type'] = 'application/atom+xml'
      req.headers['Authorization'] = "OAuth #{oauth2_token}"
      req.headers['GData-Version'] = '3.0'
    end
    logger.debug("#fetch")
    logger.debug(path)
    logger.debug(response.status)
    logger.debug(response.body)
    if response.status == 200
      object.class.from_xml(response.body)
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
    xml = object.to_xml
    response = connection.post("/m8/feeds/#{object.class.path_part}/default/full") do |req|
      req.headers['Content-Type'] = 'application/atom+xml'
      req.headers['Authorization'] = "OAuth #{oauth2_token}"
      req.headers['GData-Version'] = '3.0'
      req.body = xml
    end
    logger.debug("#create")
    logger.debug(response.status)
    logger.debug(response.body)
    if response.status == 201
      object.class.from_xml(response.body)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def update(object)
    xml = object.to_xml
    remote_id = object.google_id.split("/").last
    url = "/m8/feeds/#{object.class.path_part}/default/full/#{remote_id}"
    response = connection.put(url) do |req|
      req.headers['Content-Type'] = 'application/atom+xml'
      req.headers['Authorization'] = "OAuth #{oauth2_token}"
      req.headers['GData-Version'] = '3.0'
      req.headers['If-Match'] = object.etag
      req.body = xml
    end
    logger.debug("#update #{url}")
    logger.debug(response.status)
    logger.debug(response.body)
    if response.status == 200
      object.class.from_xml(response.body)
    else
      raise GoogleR::Error.new(response.status, response.body)
    end
  end

  def contacts(params = {})
    klass = GoogleR::Contact
    objects = fetch_objects(klass, params)
    objects.map { |e| klass.from_xml(e) }
  end

  def groups(params = {})
    klass = GoogleR::Group
    objects = fetch_objects(klass, params)
    objects.map { |e| klass.from_xml(e) }
  end

  def fetch_objects(object_class, params = {})
    current_count = 0
    per_page = 500
    results = []
    start_index = 1
    begin
      query_params = {
        :"max-results" => per_page,
        :"start-index" => start_index,
      }.merge(params)

      path = "/m8/feeds/#{object_class.path_part}/default/full/?#{Faraday::Utils.build_query(query_params)}"
      response = connection.get(path) do |req|
        req.headers['Content-Type'] = 'application/atom+xml'
        req.headers['Authorization'] = "OAuth #{oauth2_token}"
        req.headers['GData-Version'] = '3.0'
      end
      if response.status == 200
        doc = Nokogiri::XML.parse(response.body)
        total_results = doc.search("//openSearch:totalResults").first.inner_html.to_i
        entries = doc.search("entry")
        current_count = entries.size
        next if current_count == 0
        results += entries.map { |e| e.to_s }
        start_index += current_count
      else
        raise GoogleR::Error.new(response.status, response.body)
      end
    end while current_count == per_page
    results
  end

  def connection
    @connection ||= Faraday.new(:url => "https://www.google.com", :ssl => {:verify => false})
  end
end
