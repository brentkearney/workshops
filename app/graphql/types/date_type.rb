# app/graphql/types/date_type.rb

module Types
  class DateType < Types::BaseScalar
    def self.coerce_input(value, _context)
      Date.parse(value.to_s)
    end

    def self.coerce_result(value, _context)
      Date.parse(value.to_s)
    end
  end
end
