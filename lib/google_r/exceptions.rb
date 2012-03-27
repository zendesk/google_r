class GoogleR
  class Error < Exception
    def initialize(status, response)
      @status, @response = status, response
    end

    def message
      [
        "Response code: #{@status}",
        "Response body: #{@response}",
      ].join("\n")
    end
  end
end
