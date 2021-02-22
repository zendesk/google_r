require 'spec_helper'

describe GoogleR::Contact do
  before(:each) do
    @single_group_path = "spec/fixtures/single_group.xml"
    @parsed_xml = Nokogiri::XML.parse(File.read(@single_group_path))
    @parsed_xml.remove_namespaces!
    @group = GoogleR::Group.from_xml(@parsed_xml.root)
  end

  it "should load id and etag from xml" do
    expect(@group.google_id).to eq("http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/5e8cb5e00cc22016")
    expect(@group.etag).to eq("\"Qnw-eTVSLit7I2A9WhVREUgNQQ0.\"")
  end

  it "should load content from xml" do
    expect(@group.title).to eq("Grupa 52")
  end

  it "should load updated from xml" do
    expect(@group.updated).to eq(Time.parse("2012-03-19T11:48:13.251Z"))
  end

  it "should load extended from xml" do
    expect(@group.property.name).to eq("Grupa 55")
    expect(@group.property.info).to eq("To jest grupa")
  end

  it "should generate valid xml" do
    xml = @group.to_google
    g = Nokogiri::XML.parse(xml).root

    expect(g.name).to eq("entry")
    expect(g.namespace.prefix).to eq("atom")

    expect(g.search("id").size).to eq(1)
  end

  context "google api expectations" do
    it "should send application/xml+atom content type for groups" do
      headers = GoogleR::Group.api_headers
      expect(headers).to have_key("Content-Type")
      expect(headers["Content-Type"]).to eq("application/atom+xml")
    end
  end
end
