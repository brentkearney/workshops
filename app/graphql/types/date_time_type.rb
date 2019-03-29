# app/graphql/types/date_time_type.rb

module Types
  class DateTimeType < Types::BaseScalar
    def self.coerce_input(value, _context)
      Time.zone.parse(value.to_s)
    end

    def self.coerce_result(value, _context)
      Time.zone.parse(value.to_s).utc.iso8601
    end
  end
end
