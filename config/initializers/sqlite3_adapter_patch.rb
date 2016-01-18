# Monkey-patch SQLite3 so that boolean queries work
# from http://stackoverflow.com/questions/6013121/rails-3-sqlite3-boolean-false
module ActiveRecord
  module ConnectionAdapters
    class SQLite3Adapter < AbstractAdapter
      def quoted_true
        "'t'"
      end

      def quoted_false
        "'f'"
      end
    end
  end
end
