require 'ostruct'

class GoogleR::Group
  Property = Struct.new(:name, :info)

  attr_accessor :property, :etag, :google_id, :title, :updated

  def self.url
    "https://www.google.com"
  end

  def self.path
    "/m8/feeds/groups/default/full/"
  end

  def self.api_headers
    {
      'GData-Version' => '3.0',
      'Content-Type' => 'application/atom+xml',
    }
  end

  def path
    if new?
      self.class.path
    else
      self.class.path + google_id.split("/")[-1]
    end
  end

  def to_google
    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      root_attrs = {
        'xmlns:atom' => 'http://www.w3.org/2005/Atom',
        'xmlns:gd' => 'http://schemas.google.com/g/2005',
      }
      root_attrs["gd:etag"] = self.etag unless new?
      xml.entry(root_attrs) do
        xml.id_ self.google_id unless new?
        xml.updated self.updated.strftime("%Y-%m-%dT%H:%M:%S.%LZ") unless self.updated.nil?

        xml['atom'].title({:type => "text"}, self.title) unless self.title.nil?
        if self.property
          xml['gd'].extendedProperty({:name => self.property.name}) do
            xml.info self.property.info unless self.property.info.nil?
          end
        end
        xml.parent.namespace = xml.parent.namespace_definitions.find { |ns| ns.prefix == "atom" }
      end
    end
    builder.to_xml
  end

  def self.from_xml(doc, *attrs)
    is_collection = doc.search("totalResults").size > 0
    return doc.search("entry").map { |e| from_xml(e) } if is_collection

    group = self.new

    google_id = doc.search("id")
    if google_id.empty?
      group.etag = group.google_id = nil
    else
      group.etag = doc["etag"]
      group.google_id = google_id.inner_text
    end

    title = doc.search("title")
    group.title = title.inner_text unless title.size == 0

    updated = doc.search("updated")
    group.updated = Time.parse(updated.inner_text) unless updated.empty?

    extended = doc.search("extendedProperty")
    if extended.size != 0
      info = extended.search("info")
      info = info.size == 0 ? nil : info.inner_text
      property = GoogleR::Group::Property.new(extended[0][:name], info)
      group.property = property
    end

    group
  end

  def new?
    self.google_id.nil?
  end
end
