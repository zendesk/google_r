require 'spec_helper'

describe GoogleR do

  let(:api) { GoogleR.new("token") }

  it "should process contacts" do
    google_contacts = File.read('spec/fixtures/contact_list.xml');
    connection_get_answer = double(:body => google_contacts,
                                 :status => 200,
                                 :headers => {"Content-Type" => "xml"})
    allow(api).to receive_message_chain(:connection, :get).and_return(connection_get_answer)

    data = api.contacts
    expect(data.size).to eq(2)

    contact_1 = data.find { |e| e.full_name == "Awangarda druga" }
    expect(contact_1).not_to be_nil

    contact_2 = data.find { |e| e.full_name == "Sir Bartek Maciej Niemtur III" }
    expect(contact_2).not_to be_nil
  end

  it "should process groups"

  it "should process events"

  it "should handle accounts which have 0 contacts" do
    no_contacts = File.read('spec/fixtures/no_contacts.xml')
    connection_get_answer = double(:body => no_contacts,
                                 :status => 200,
                                 :headers => {"Content-Type" => "xml"})
    allow_any_instance_of(GoogleR).to receive_message_chain(:connection, :get).and_return(connection_get_answer)

    expect(api.connection(GoogleR::Contact)).to receive(:get)
    expect(api.contacts).to be_empty
  end

  it "should raise error if request fails" do
    connection_get_answer = double(:body => "Failed :(",
                                 :status => 400)
    allow_any_instance_of(GoogleR).to receive_message_chain(:connection, :get).and_return(connection_get_answer)
    ex = nil
    begin
      api.contacts
    rescue GoogleR::Error => e
      ex = e
    end
    expect(ex.class).to eq(GoogleR::Error)
    expect(ex.message).to include("400")
    expect(ex.message).to include("Failed :(")
  end

  describe "test_access" do
    context "when test response is 200" do
      before do
        response = double(:status => 200)
        expect(api).to receive(:make_request).and_return(response)
      end

      it "returns true" do
        expect(api.test_access).to eq(true)
      end
    end

    context "when test response is 401" do
      before do
        response = double(:status => 401)
        expect(api).to receive(:make_request).and_return(response)
      end

      it "returns true" do
        expect(api.test_access).to eq(false)
      end
    end

    context "when test response is somethig else" do
      before do
        response = double(:status => 500, :body => "Server error")
        expect(api).to receive(:make_request).and_return(response)
      end

      it "raises GoogleR::Error" do
        expect {
          api.test_access
        }.to raise_error(GoogleR::Error)
      end
    end
  end
end
