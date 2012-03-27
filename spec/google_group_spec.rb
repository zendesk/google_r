require 'spec_helper'

describe GoogleR::Contact do
  before(:each) do
    @single_group_path = "spec/fixtures/single_group.xml"
    @group = GoogleR::Group.from_xml(File.read(@single_group_path))
  end

  it "should load id and etag from xml" do
    @group.google_id.should == "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/5e8cb5e00cc22016"
    @group.etag.should == "\"Qnw-eTVSLit7I2A9WhVREUgNQQ0.\""
  end

  it "should load content from xml" do
    @group.title.should == "Grupa 52"
  end

  it "should load updated from xml" do
    @group.updated.should == Time.parse("2012-03-19T11:48:13.251Z")
  end

  it "should load extended from xml" do
    @group.property.name.should == "Grupa 55"
    @group.property.info.should == "To jest grupa"
  end

  it "should generate valid xml" do
    xml = @group.to_xml
    g = GoogleR::Group.from_xml(xml)
    g = Nokogiri::XML.parse(xml).first_element_child

    g.name.should == "entry"
    g.namespace.prefix.should == "atom"

    g.search("id").size.should == 1
  end
end
