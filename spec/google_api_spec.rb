require 'spec_helper'

describe GoogleR do

  let(:api) { GoogleR.new("token") }

  it "should process contacts" do
    google_contacts = File.read('spec/fixtures/contact_list.xml');
    connection_get_answer = mock(:body => google_contacts,
                                 :status => 200,
                                 :headers => {"Content-Type" => "xml"})
    api.stub_chain(:connection, :get).and_return(connection_get_answer)

    data = api.contacts
    data.size.should == 2

    contact_1 = data.find { |e| e.full_name == "Awangarda druga" }
    contact_1.should_not be_nil

    contact_2 = data.find { |e| e.full_name == "Sir Bartek Maciej Niemtur III" }
    contact_2.should_not be_nil
  end

  it "should process groups"

  it "should process events"

  it "should handle accounts which have 0 contacts" do
    no_contacts = File.read('spec/fixtures/no_contacts.xml')
    connection_get_answer = mock(:body => no_contacts,
                                 :status => 200,
                                 :headers => {"Content-Type" => "xml"})
    GoogleR.any_instance.stub_chain(:connection, :get).and_return(connection_get_answer)

    api.connection(GoogleR::Contact).should_receive(:get)
    api.contacts.should be_empty
  end

  it "should raise error if request fails" do
    connection_get_answer = mock(:body => "Failed :(",
                                 :status => 400)
    GoogleR.any_instance.stub_chain(:connection, :get).and_return(connection_get_answer)
    ex = nil
    begin
      api.contacts
    rescue GoogleR::Error => e
      ex = e
    end
    ex.class.should == GoogleR::Error
    ex.message.should include("400")
    ex.message.should include("Failed :(")
  end

  describe "test_access" do
    context "when test response is 200" do
      before do
        response = mock(:status => 200)
        api.should_receive(:make_request).and_return(response)
      end

      it "returns true" do
        api.test_access.should eq(true)
      end
    end

    context "when test response is 401" do
      before do
        response = mock(:status => 401)
        api.should_receive(:make_request).and_return(response)
      end

      it "returns true" do
        api.test_access.should eq(false)
      end
    end

    context "when test response is somethig else" do
      before do
        response = mock(:status => 500, :body => "Server error")
        api.should_receive(:make_request).and_return(response)
      end

      it "raises GoogleR::Error" do
        expect {
          api.test_access
        }.to raise_error(GoogleR::Error)
      end
    end
  end

  context "requests listeners" do
    let(:event_handler) { double }

    before do
      google_calendars = File.read('spec/fixtures/calendar_list.json');
      allow_any_instance_of(Faraday::Connection).to receive(:send).and_return(
        mock(:body => google_calendars,
             :status => 200,
             :headers => {"Content-Type" => "json"})
      )
    end

    it "adds listeners" do
      expect((api.subscribe_request_listener(:get) { |event| event }).size).to eq(1)
    end

    it  "calls block on fetch" do
      expect(event_handler).to receive(:handle)
      api.subscribe_request_listener(:get) { |event| event_handler.handle(event) }

      api.calendars
    end

    it "doesn't try to call when listener is not subscribed" do
      expect{ api.calendars }.not_to raise_error(NoMethodError)
    end

  end
end
