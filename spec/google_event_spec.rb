require 'spec_helper'

describe GoogleR::Event do
  before(:each) do
  end

  let(:event) { GoogleR::Event.new(nil) }

  it "represents with valid-formatted times" do
    time = Time.new(2012, 6, 4, 9, 34, 48, "-04:00")
    event.start_time = time
    format = event.to_google
    format.should include("2012-06-04T09:34:48-04:00")
  end

  it "parses events which take whole day" do
    json = {
      "kind" => "calendar#event",
      "start" => {
        "date" => "2012-03-04",
      },
      "end" => {
        "date" => "2012-03-05",
      },
      "updated" => Time.now.to_s,
      "created" => Time.now.to_s,
    }

    event = GoogleR::Event.from_json(json, mock(:calendar => nil))
    event.start_time.should == Time.parse("2012-03-04")
    event.end_time.should == Time.parse("2012-03-05")
  end
end
