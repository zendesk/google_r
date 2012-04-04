require 'ostruct'

class GoogleR::Token
  attr_accessor :issued_to, :audience, :scopes, :expires_at, :access_type, :token

  def initialize(token)
    self.token = token
    self.scopes = []
  end

  def self.url
    "https://www.googleapis.com"
  end

  def self.api_headers
    {}
  end

  def path
    "/oauth2/v2/tokeninfo"
  end

  def self.from_json(json, *attrs)
    token = self.new(*attrs)
    token.issued_to = json["issued_to"]
    token.audience = json["audience"]
    token.scopes = json["scope"].split(" ")
    token.expires_at = Time.at(Time.now.to_i + json["expires_in"])
    token.access_type = json["access_type"]
    token
  end

  def expires_in
    expires_at.to_i - Time.now.to_i
  end

  def to_google(yajl_opts = {})
    Yajl::Encoder.encode({}, yajl_opts)
  end

  def new?
    self.token.nil?
  end
end
