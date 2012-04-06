require 'spec_helper'

describe GoogleR::Contact do
  before do
    single_contact_path = "spec/fixtures/single_contact.xml"
    doc = Nokogiri::XML.parse(File.read(single_contact_path))
    doc.remove_namespaces!
    @doc_root = doc.root
  end

  let(:contact) { GoogleR::Contact.from_xml(@doc_root) }
  subject { contact }

  context "should load id and etag from xml" do
    its(:google_id) { should == "http://www.google.com/m8/feeds/contacts/michal%40futuresimple.com/base/2f30e7d8bf01953" }
    its(:etag) { should == "\"Q3o6cDVSLit7I2A9WhVSGEkOQgI.\"" }
  end

  context "should load emails from xml" do
    let (:emails) { GoogleR::Contact.from_xml(@doc_root).emails }
    subject { emails }
    its(:size) { should == 4 }

    context "home_email" do
      subject { emails.find { |e| e.rel == "http://schemas.google.com/g/2005#home" } } 
      its(:address) { should == "home@example.com" }
      its(:label)   { should be_nil }
      its(:primary) { should be_true }
    end

    context "work_email" do
      subject { emails.find { |e| e.rel == "http://schemas.google.com/g/2005#work" } } 
      its(:address) { should == "work@example.com" }
      its(:label)   { should be_nil }
      its(:primary) { should be_false }
    end

    context "other_email" do
      subject { emails.find { |e| e.rel == "http://schemas.google.com/g/2005#other" } } 
      its(:address) { should == "other@example.com" }
      its(:label)   { should be_nil }
      its(:primary) { should be_false }
    end

    context "custom_email" do
      subject { emails.find { |e| e.rel.nil? } }
      its(:address) { should == "nonstandard@example.com" }
      its(:label)   { should == "Non standard" }
      its(:primary) { should be_false }
    end

  end

  context "should load phones from xml" do
    let (:phones) { GoogleR::Contact.from_xml(@doc_root).phones }
    subject { phones }
    its(:size) { should == 4 }

    context "home_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#home" } }
      its(:text) { should == "444-home" }
    end

    context "work_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#work" } }
      its(:text) { should == "023-office" }
    end

    context "mobile_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#mobile" } }
      its(:text) { should == "43-mobile" }
    end

    context "main_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#main" } }
      its(:text) { should == "888-main" }
    end
  end

  context "should load name from xml" do
    its(:name_prefix)     { should == "Sir" }
    its(:given_name)      { should == "Mike" }
    its(:additional_name) { should == "Thomas" }
    its(:family_name)     { should == "Bugno" }
    its(:name_suffix)     { should == "XI" }
    its(:full_name)       { should == "Sir Mike Thomas Bugno XI" }
  end

  context "should load content from xml" do
    its(:content) { should == "Notes about Mike" }
  end

  context "should load updated from xml" do
    its(:updated) { should == Time.parse("2012-03-15T20:49:22.418Z") }
  end

  context "should load organisations from xml" do
    let (:organizations) { GoogleR::Contact.from_xml(@doc_root).organizations }
    subject { organizations }
    its(:size) { should == 1 }

    context "single organization" do
      let (:organization) { GoogleR::Contact.from_xml(@doc_root).organizations.first }
      subject { organization }
      its(:rel)   { should == "http://schemas.google.com/g/2005#other" }
      its(:name)  { should == "FutureSimple" }
      its(:title) { should == "Coder" }
    end
  end

  context "should load user nickname from xml" do
    its(:nickname) { should = "Majki"}
  end

  context "should load addresses from xml" do
    let (:addresses) { GoogleR::Contact.from_xml(@doc_root).addresses }
    subject { addresses }
    its(:size) { should == 2 }

    context "home" do
      subject { addresses.find { |e| e.rel == "http://schemas.google.com/g/2005#home" } }
      its(:street)       { should == "ulica" }
      its(:neighborhood) { should == "okolica" }
      its(:pobox)        { should == "skrytka" }
      its(:postcode)     { should == "kod" }
      its(:city)         { should == "miasto" }
      its(:region)       { should == "wojewodztwo" }
      its(:country)      { should == "kraj" }
    end

    context "work" do
      subject { addresses.find { |e| e.rel == "http://schemas.google.com/g/2005#work" } }
      its(:street)       { should == "ulica2" }
      its(:neighborhood) { should == "okolica2" }
      its(:pobox)        { should == "skrytka2" }
      its(:postcode)     { should == "kod2" }
      its(:city)         { should == "miasto2" }
      its(:region)       { should == "wojewodztwo2" }
      its(:country)      { should == "kraj2" }
    end

  end

  context "should load group membership from xml" do
    let (:groups) { GoogleR::Contact.from_xml(@doc_root).groups }
    subject { groups }
    its(:size) { should == 2 }

    context "first" do
      google_id = "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/6"
      subject { groups.find { |e| e.google_id == google_id } }
      it { should_not be_nil }
    end

    context "last" do
      google_id = "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/5747930b8e7844f6"
      subject { groups.find { |e| e.google_id == google_id } }
      it { should_not be_nil }
    end
  end

  context "should treat contact without google_id as new?" do
    subject { GoogleR::Contact.new }
    it { should be_new }
  end

  context "should treat contact with google_id as !new?" do
    it { should_not be_new }
  end

  context "should load user fields from xml" do
    its(:user_fields) { should == {"own key" => "Own value"} }
  end

  it "should load websites from xml" do
    contact.websites.map { |e| e.href }.sort.should == ["glowna.com", "sluzbowy.com"].sort
    contact.websites.map { |e| e.rel }.sort.should == ["work", "home-page"].sort
  end

  it "should generate valid xml" do
    xml = contact.to_google
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
