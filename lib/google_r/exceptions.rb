class GoogleR
  class Error < Exception
    attr_reader :status, :response

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
