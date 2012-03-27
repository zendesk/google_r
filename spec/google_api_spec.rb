require 'spec_helper'

describe GoogleR do
  before(:each) do
    @api = GoogleR.new("token")
  end

  it "should process contacts" do
    google_contacts = File.read('spec/fixtures/contact_list.xml');
    contacts = Nokogiri::XML.parse(google_contacts).search("entry").map { |e| e.to_s }
    @api.should_receive(:fetch_objects).and_return(contacts)

    data = @api.contacts
    data.size.should == 2

    contact_1 = data.find { |e| e.full_name == "Awangarda druga" }
    contact_1.should_not be_nil

    contact_2 = data.find { |e| e.full_name == "Sir Bartek Maciej Niemtur III" }
    contact_2.should_not be_nil
  end

  it "should handle accounts which have 0 contacts" do
    no_contacts = File.read('spec/fixtures/no_contacts.xml')
    @api.connection.should_receive(:get).and_return(mock(:body => no_contacts, :status => 200))
    @api.contacts.should be_empty
  end

  it "should raise error if request fails" do
    @api.connection.should_receive(:get).and_return(mock(:body => "Failed :(", :status => 400))
    ex = nil
    begin
      @api.contacts
    rescue GoogleR::Error => e
      ex = e
    end
    ex.class.should == GoogleR::Error
    ex.message.should include("400")
    ex.message.should include("Failed :(")
  end
end
