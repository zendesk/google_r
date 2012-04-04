require 'spec_helper'

describe GoogleR::Contact do
  before(:each) do
    @single_contact_path = "spec/fixtures/single_contact.xml"
    doc = Nokogiri::XML.parse(File.read(@single_contact_path))
    doc.remove_namespaces!
    @contact = GoogleR::Contact.from_xml(doc.root)
  end

  it "should load id and etag from xml" do
    @contact.google_id.should == "http://www.google.com/m8/feeds/contacts/michal%40futuresimple.com/base/2f30e7d8bf01953"
    @contact.etag.should == "\"Q3o6cDVSLit7I2A9WhVSGEkOQgI.\""
  end

  it "should load emails from xml" do
    @contact.emails.size.should == 4
    emails = @contact.emails

    home_email = emails.find { |e| e.rel == "http://schemas.google.com/g/2005#home" }
    home_email.address.should == "home@example.com"
    home_email.label.should be_nil
    home_email.primary.should be_true

    work_email = emails.find { |e| e.rel == "http://schemas.google.com/g/2005#work" }
    work_email.address.should == "work@example.com"
    work_email.label.should be_nil
    work_email.primary.should be_false

    other_email = emails.find { |e| e.rel == "http://schemas.google.com/g/2005#other" }
    other_email.address.should == "other@example.com"
    other_email.label.should be_nil
    other_email.primary.should be_false

    custom_email = emails.find { |e| e.rel.nil? }
    custom_email.address.should == "nonstandard@example.com"
    custom_email.label.should == "Non standard"
    custom_email.primary.should be_false
  end

  it "should load phones from xml" do
    @contact.phones.size.should == 4
    phones = @contact.phones

    home_phone = phones.find { |e| e.rel == "http://schemas.google.com/g/2005#home" }
    home_phone.text.should == "444-home"

    work_phone = phones.find { |e| e.rel == "http://schemas.google.com/g/2005#work" }
    work_phone.text.should == "023-office"

    mobile_phone = phones.find { |e| e.rel == "http://schemas.google.com/g/2005#mobile" }
    mobile_phone.text.should == "43-mobile"

    main_phone = phones.find { |e| e.rel == "http://schemas.google.com/g/2005#main" }
    main_phone.text.should == "888-main"
  end

  it "should load name from xml" do
    @contact.name_prefix.should == "Sir"
    @contact.given_name.should == "Mike"
    @contact.additional_name.should == "Thomas"
    @contact.family_name.should == "Bugno"
    @contact.name_suffix.should == "XI"
    @contact.full_name.should == "Sir Mike Thomas Bugno XI"
  end

  it "should load content from xml" do
    @contact.content.should == "Notes about Mike"
  end

  it "should load updated from xml" do
    @contact.updated.should == Time.parse("2012-03-15T20:49:22.418Z")
  end

  it "should load organisation from xml" do
    organizations = @contact.organizations
    organizations.size.should == 1
    org = organizations[0]
    org.rel.should == "http://schemas.google.com/g/2005#other"
    org.name.should == "FutureSimple"
    org.title.should == "Coder"
  end

  it "should load user nickname from xml" do
    @contact.nickname = "Majki"
  end

  it "should load addresses from xml" do
    addresses = @contact.addresses
    addresses.size.should == 2

    a1 = addresses.find { |e| e.rel == "http://schemas.google.com/g/2005#home" }
    a1.street.should == "ulica"
    a1.neighborhood.should == "okolica"
    a1.pobox.should == "skrytka"
    a1.postcode.should == "kod"
    a1.city.should == "miasto"
    a1.region.should == "wojewodztwo"
    a1.country.should == "kraj"

    a2 = addresses.find { |e| e.rel == "http://schemas.google.com/g/2005#work" }
    a2.street.should == "ulica2"
    a2.neighborhood.should == "okolica2"
    a2.pobox.should == "skrytka2"
    a2.postcode.should == "kod2"
    a2.city.should == "miasto2"
    a2.region.should == "wojewodztwo2"
    a2.country.should == "kraj2"
  end

  it "should load group membership from xml" do
    groups = @contact.groups
    groups.size.should == 2

    g1 = groups.find { |e| e.google_id == "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/6" }
    g1.should_not be_nil

    g2 = groups.find { |e| e.google_id == "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/5747930b8e7844f6" }
    g2.should_not be_nil
  end

  it "should treat contact without google_id as new?" do
    GoogleR::Contact.new.should be_new
  end

  it "should treat contact with google_id as !new?" do
    @contact.should_not be_new
  end

  it "should load user fields from xml" do
    @contact.user_fields.should == {"own key" => "Own value"}
  end

  it "should load websites from xml" do
    @contact.websites.map { |e| e.href }.sort.should == ["glowna.com", "sluzbowy.com"].sort
    @contact.websites.map { |e| e.rel }.sort.should == ["work", "home-page"].sort
  end

  it "should generate valid xml" do
    xml = @contact.to_google
    c = Nokogiri::XML.parse(xml)
    c = c.root

    c.name.should == "entry"
    c.namespace.prefix.should == "atom"

    c.search("id").size.should == 1

    c.search("./gd:name/gd:givenName").size.should == 1
    c.search("./gd:name/gd:givenName").inner_text.should == "Mike"
    c.search("./gd:name/gd:additionalName").size.should == 1
    c.search("./gd:name/gd:additionalName").inner_text.should == "Thomas"
    c.search("./gd:name/gd:familyName").size.should == 1
    c.search("./gd:name/gd:familyName").inner_text.should == "Bugno"
    c.search("./gd:name/gd:namePrefix").size.should == 1
    c.search("./gd:name/gd:namePrefix").inner_text.should == "Sir"
    c.search("./gd:name/gd:nameSuffix").size.should == 1
    c.search("./gd:name/gd:nameSuffix").inner_text.should == "XI"

    c.search("./atom:content").inner_text.should == "Notes about Mike"

    c.search("./gContact:nickname").inner_text.should == "Majki"

    c.search("./gd:phoneNumber").map { |e| e.inner_text }.sort.should == ["43-mobile", "023-office", "444-home", "888-main"].sort

    c.search("./gd:email").map { |e| e[:address] }.should == ["home@example.com", "work@example.com", "other@example.com", "nonstandard@example.com"]
    c.search("./gd:email").map { |e| e[:primary] }.should == ["true", "false", "false", "false"]

    c.search("./gd:organization/gd:orgName").size.should == 1
    c.search("./gd:organization/gd:orgName").inner_text.should == "FutureSimple"
    c.search("./gd:organization/gd:orgTitle").size.should == 1
    c.search("./gd:organization/gd:orgTitle").inner_text.should == "Coder"

    c.search("./gContact:groupMembershipInfo").size.should == 2
    c.search("./gContact:groupMembershipInfo").map { |e| e[:deleted] }.should == ["false", "false"]

    c.search("./gContact:userDefinedField").size.should == 1
    c.search("./gContact:userDefinedField")[0][:key].should == "own key"
    c.search("./gContact:userDefinedField")[0][:value].should == "Own value"

    websites = c.search("./gContact:website")
    websites.map { |e| e[:href] }.sort.should == ["glowna.com", "sluzbowy.com"].sort
    websites.map { |e| e[:rel] }.sort.should == ["work", "home-page"].sort
  end
end
