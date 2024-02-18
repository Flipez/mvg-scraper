# frozen_string_literal: true

require 'logger'

module MVG
  ###
  # Provides logger with custom formatter
  class Logging
    attr_reader :logger

    def initialize
      @logger = Logger.new($stdout)

      logger.formatter = proc do |_severity, datetime, _progname, msg|
        "#{JSON.dump(timestamp: datetime.to_s, message: msg)}\n"
      end
    end
  end
end
