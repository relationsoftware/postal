# frozen_string_literal: true

module Postal
  module MessageDB
    class Statistics

      def initialize(database)
        @database = database
      end

      STATS_GAPS = { hourly: :hour, daily: :day, monthly: :month, yearly: :year }.freeze
      COUNTERS = [:incoming, :outgoing, :spam, :bounces, :held].freeze

      #
      # Increment an appropriate counter
      #
      def increment_one(type, field, time = Time.now)
        time = time.utc
        initial_values = COUNTERS.map do |c|
          field.to_sym == c ? 1 : 0
        end

        time_i = time.send("beginning_of_#{STATS_GAPS[type]}").utc.to_i
        sql_query = "INSERT INTO `#{@database.database_name}`.`stats_#{type}` (time, #{COUNTERS.join(', ')})"
        sql_query << " VALUES (#{time_i}, #{initial_values.join(', ')})"
        sql_query << " ON DUPLICATE KEY UPDATE #{field} = #{field} + 1"
        @database.query(sql_query)
      end

      #
      # Increment all stats counters
      #
      def increment_all(time, field)
        STATS_GAPS.each_key do |type|
          increment_one(type, field, time)
        end
      end

      #
      # Get a statistic (or statistics)
      #
      def get(type, counters, start_date = Time.now, quantity = 10)
        # Use UTC for database queries but convert to user's timezone for display
        start_date_utc = start_date.utc
        items = quantity.times.each_with_object({}) do |i, hash|
          utc_time = (start_date_utc - i.send(STATS_GAPS[type])).send("beginning_of_#{STATS_GAPS[type]}").utc
          hash[utc_time] = counters.each_with_object({}) do |c, h|
            h[c] = 0
          end
        end
        @database.select("stats_#{type}", where: { time: items.keys.map(&:to_i) }, fields: [:time] | counters).each do |data|
          time = Time.at(data.delete("time")).utc
          data.each do |key, value|
            items[time][key.to_sym] = value if items.key?(time)
          end
        end
        # Convert UTC times to user's timezone for display
        items.map { |utc_time, values| [Time.zone.at(utc_time.to_i), values] }.reverse
      end

    end
  end
end
