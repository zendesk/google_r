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
end
