require 'ostruct'

class GoogleR::Contact
  Email = Struct.new(:address, :display_name, :label, :rel, :primary)
  Phone = Struct.new(:rel, :text)
  Organization = Struct.new(:name, :title, :rel)
  Address = Struct.new(:street, :neighborhood, :pobox, :postcode, :city, :region, :country, :rel)
  Website = Struct.new(:href, :rel)

  attr_reader :emails, :phones, :organizations, :addresses, :groups, :websites
  attr_accessor :given_name, :additional_name, :name_prefix, :name_suffix, :family_name,
                :google_id, :etag, :content, :updated, :user_fields, :nickname

  def initialize
    @emails = []
    @phones = []
    @organizations = []
    @addresses = []
    @groups = []
    @websites = []
    @user_fields = {}
  end

  def self.url
    "https://www.google.com"
  end

  def self.path
      "/m8/feeds/contacts/default/full/"
    #if new?
      #"/m8/feeds/contacts/default/full/"
    #else
      #"/m8/feeds/contacts/default/full/#{google_id}"
    #end
  end

  def self.path_part
    "contacts"
  end

  def full_name
    [name_prefix, given_name, additional_name, family_name, name_suffix].compact.join(" ")
  end

  def to_xml
    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      root_attrs = {
        'xmlns:atom' => 'http://www.w3.org/2005/Atom',
        'xmlns:gd' => 'http://schemas.google.com/g/2005',
        'xmlns:gContact' => 'http://schemas.google.com/contact/2008',
      }
      root_attrs["gd:etag"] = self.etag unless new?
      xml.entry(root_attrs) do
        unless new?
          xml.id_ self.google_id
        end

        xml.updated self.updated.strftime("%Y-%m-%dT%H:%M:%S.%LZ") unless self.updated.nil?

        if self.full_name != ''
          xml['gd'].name do
            xml['gd'].givenName self.given_name unless self.given_name.nil?
            xml['gd'].additionalName self.additional_name unless self.additional_name.nil?
            xml['gd'].familyName self.family_name unless self.family_name.nil?
            xml['gd'].namePrefix self.name_prefix unless self.name_prefix.nil?
            xml['gd'].nameSuffix self.name_suffix unless self.name_suffix.nil?
          end
        end

        xml['atom'].content({'type' => 'text'}, self.content) unless self.content.nil?
        xml['gContact'].nickname self.nickname unless self.nickname.nil?

        phones.each do |phone|
          xml['gd'].phoneNumber({'rel' => phone.rel}, phone.text)
        end

        emails.each do |email|
          attrs = {'address' => email.address}
          attrs['rel'] = email.rel if email.rel
          attrs['label'] = email.label if email.label
          attrs['primary'] = email.primary
          xml['gd'].email(attrs)
        end

        organizations.each do |org|
          xml['gd'].organization({:rel => org.rel}) do
            xml['gd'].orgName org.name
            xml['gd'].orgTitle org.title
          end
        end

        addresses.each do |address|
          xml['gd'].structuredPostalAddress({'rel' => address.rel}) do
            xml['gd'].street address.street unless address.street.nil?
            xml['gd'].neighborhood address.neighborhood unless address.neighborhood.nil?
            xml['gd'].pobox address.pobox unless address.pobox.nil?
            xml['gd'].postcode address.postcode unless address.postcode.nil?
            xml['gd'].city address.city unless address.city.nil?
            xml['gd'].region address.region unless address.region.nil?
            xml['gd'].country address.country unless address.country.nil?
          end
        end

        user_fields.each do |key, value|
          xml['gContact'].userDefinedField({'key' => key, 'value' => value})
        end

        websites.each do |website|
          xml['gContact'].website({'href' => website.href, 'rel' => website.rel})
        end

        groups.each do |group|
          xml['gContact'].groupMembershipInfo({'href' => group.google_id, 'deleted' => 'false'})
        end

        xml.parent.namespace = xml.parent.namespace_definitions.find { |ns| ns.prefix == "atom" }
      end
    end
    builder.to_xml
  end

  def add_email(email)
    @emails << email
  end

  def add_phone(phone)
    @phones << phone
  end

  def add_organization(organization)
    @organizations << organization
  end

  def add_address(address)
    @addresses << address
  end

  def add_group(group)
    @groups << group
  end

  def add_website(website)
    @websites << website
  end

  def self.from_xml(xml)
    doc = Nokogiri::XML.parse(xml)


    doc.search("entry")

    doc.remove_namespaces!
    doc = doc.root
    contact = GoogleR::Contact.new

    google_id = doc.search("id")

    if google_id.empty?
      contact.etag = contact.google_id = nil
    else
      contact.etag = doc["etag"]
      contact.google_id = google_id.inner_text
    end

    doc.search("email").each do |email|
      contact.add_email(GoogleR::Contact::Email.new(email[:address], email[:display_name], email[:label], email[:rel], email[:primary] == "true"))
    end

    doc.search("phoneNumber").each do |phone|
      contact.add_phone(GoogleR::Contact::Phone.new(phone[:rel], phone.inner_text))
    end

    doc.search("organization").each do |org|
      name = org.search("orgName").inner_text
      title = org.search("orgTitle").inner_text
      rel = org[:rel]
      contact.add_organization(GoogleR::Contact::Organization.new(name, title, rel))
    end

    doc.search("structuredPostalAddress").each do |address|
      rel = address[:rel]
      street = address.search("street").inner_text
      neighborhood = address.search("neighborhood").inner_text
      pobox = address.search("pobox").inner_text
      postcode = address.search("postcode").inner_text
      city = address.search("city").inner_text
      region = address.search("region").inner_text
      country = address.search("country").inner_text
      contact.add_address(GoogleR::Contact::Address.new(street, neighborhood, pobox, postcode, city, region, country, rel))
    end

    doc.search("userDefinedField").each do |field|
      contact.user_fields[field[:key]] = field[:value]
    end

    doc.search("groupMembershipInfo").each do |entry|
      group = GoogleR::Group.new
      group.google_id = entry[:href]
      contact.add_group(group)
    end

    doc.search("website").each do |entry|
      website = GoogleR::Contact::Website.new
      website.href = entry[:href]
      website.rel = entry[:rel]
      contact.add_website(website)
    end

    name_prefix = doc.search("name/namePrefix")
    contact.name_prefix = name_prefix.inner_text unless name_prefix.empty?

    given_name = doc.search("name/givenName")
    contact.given_name = given_name.inner_text unless given_name.empty?

    additional_name = doc.search("name/additionalName")
    contact.additional_name = additional_name.inner_text unless additional_name.empty?

    family_name = doc.search("name/familyName")
    contact.family_name = family_name.inner_text unless family_name.empty?

    name_suffix = doc.search("name/nameSuffix")
    contact.name_suffix = name_suffix.inner_text unless name_suffix.empty?

    content = doc.search("content")
    contact.content = content.inner_text unless content.empty?

    updated = doc.search("updated")
    contact.updated = Time.parse(updated.inner_text) unless updated.empty?

    nickname = doc.search("nickname")
    contact.nickname = nickname.inner_text unless nickname.empty?

    contact
  end

  def new?
    self.google_id.nil?
  end
end
