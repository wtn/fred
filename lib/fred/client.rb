# frozen_string_literal: true

require "async/http/client"
require "async/http/endpoint"
require "async/limiter"
require "uri"

module FRED
  class Client
    ENDPOINT = Async::HTTP::Endpoint.parse "https://api.stlouisfed.org/"

    RATE_LIMIT = 120
    RATE_WINDOW = 60
    MAX_RETRIES = 5
    DEFAULT_RETRY_WAIT = 2.0
    MAX_RETRY_WAIT = 60.0

    def initialize(
      api_key: ENV["FRED_API_KEY"],
      endpoint: nil,
      rate_limit: true,
      retry_wait: DEFAULT_RETRY_WAIT,
      max_retries: MAX_RETRIES
    )
      raise ArgumentError, "FRED API key required" unless api_key

      unless API_KEY_PATTERN.match?(api_key)
        raise ArgumentError, "FRED API key must be a 32-character lowercase hex string"
      end

      @api_key = api_key
      @endpoint = endpoint || ENDPOINT
      @client = Async::HTTP::Client.new(@endpoint)
      @retry_wait = retry_wait
      @max_retries = max_retries

      if rate_limit
        timing = Async::Limiter::Timing::SlidingWindow.new(
          RATE_WINDOW,
          Async::Limiter::Timing::Burst::Smooth,
          RATE_LIMIT,
        )
        @limiter = Async::Limiter::Generic.new(timing:)
      end
    end

    def close
      @client.close
    end

    # Series

    def series(series_id:, **params)
      data = get "series", series_id:, **params
      Series.parse data["seriess"].first
    end

    def series_observations(series_id:, **params)
      rows = get_all("series/observations", "observations", series_id:, **params)

      dates = rows.map { |row| row["date"] }
      values = rows.map { |row| (v = row["value"]) == "." ? nil : v }

      table = TimeSeries::Table.new("date" => dates, series_id => values)
      TimeSeries.new(table: table, index: "date", metadata: { series_id: series_id })
        .cast("date" => :date, series_id => :float64?)
    end

    def series_search(search_text:, **params)
      get_all("series/search", "seriess", search_text:, **params).map { Series.parse _1 }
    end

    def series_categories(series_id:, **params)
      get_all("series/categories", "categories", series_id:, **params).map { Category.parse _1 }
    end

    def series_release(series_id:, **params)
      data = get "series/release", series_id:, **params
      Release.parse data["releases"].first
    end

    def series_tags(series_id:, **params)
      get_all("series/tags", "tags", series_id:, **params).map { Tag.parse _1 }
    end

    def series_updates(**params)
      get_all("series/updates", "seriess", **params).map { Series.parse _1 }
    end

    # Categories

    def category(category_id: 0, **params)
      data = get "category", category_id:, **params
      Category.parse data["categories"].first
    end

    def category_children(category_id: 0, **params)
      data = get "category/children", category_id:, **params
      data["categories"].map { Category.parse _1 }
    end

    def category_series(category_id:, **params)
      get_all("category/series", "seriess", category_id:, **params).map { Series.parse _1 }
    end

    def category_tags(category_id:, **params)
      get_all("category/tags", "tags", category_id:, **params).map { Tag.parse _1 }
    end

    # Releases

    def releases(**params)
      get_all("releases", "releases", **params).map { Release.parse _1 }
    end

    def release(release_id:, **params)
      data = get "release", release_id:, **params
      Release.parse data["releases"].first
    end

    def release_dates(release_id:, **params)
      get_all("release/dates", "release_dates", release_id:, **params).map { ReleaseDate.parse _1 }
    end

    def release_series(release_id:, **params)
      get_all("release/series", "seriess", release_id:, **params).map { Series.parse _1 }
    end

    def releases_dates(**params)
      get_all("releases/dates", "release_dates", **params).map { ReleaseDate.parse _1 }
    end

    # Sources

    def sources(**params)
      get_all("sources", "sources", **params).map { Source.parse _1 }
    end

    def source(source_id:, **params)
      data = get "source", source_id:, **params
      Source.parse data["sources"].first
    end

    def source_releases(source_id:, **params)
      get_all("source/releases", "releases", source_id:, **params).map { Release.parse _1 }
    end

    # Tags

    def tags(**params)
      get_all("tags", "tags", **params).map { Tag.parse _1 }
    end

    def tags_series(tag_names:, **params)
      get_all("tags/series", "seriess", tag_names:, **params).map { Series.parse _1 }
    end

    private

    def get_all(path, key, **params)
      manual_offset = params.key?(:offset)
      offset = params.delete(:offset) || 0
      max = params.delete(:limit)
      page_size = max ? [max, 1000].min : 1000

      # Explicit offset means manual pagination — return one page
      if manual_offset
        data = get path, offset: offset, limit: page_size, **params
        items = data[key] || []
        return max ? items.first(max) : items
      end

      all_items = []

      loop do
        data = get path, offset: offset, limit: page_size, **params
        items = data[key] || []
        all_items.concat items
        count = data["count"]
        break unless count
        offset += items.length
        break if offset >= count
        break if max && all_items.length >= max
      end

      max ? all_items.first(max) : all_items
    end

    def get(path, retried: false, **params)
      params[:api_key] = @api_key
      params[:file_type] = "json"
      query = URI.encode_www_form(params.compact)
      request_path = "/fred/#{path}?#{query}"

      retries = 0

      Sync do |task|
        loop do
          @limiter&.acquire
          begin
            response = @client.get(request_path)
            body = response.read

            break JSON.parse(body) if response.success?

            data = JSON.parse(body) rescue nil
            message = data&.dig("error_message") || "HTTP #{response.status}"

            unless response.status == 429 && retries < @max_retries
              raise Error, message
            end

            # Compute the delay while the response (and its headers) are still
            # open; the ensure block below then releases the limiter slot and
            # closes the response *before* we sleep, so a throttled request
            # never holds a slot or blocks other in-flight requests.
            wait = retry_delay(response, retries)
          ensure
            @limiter&.release
            response&.close
          end

          retries += 1
          task.sleep wait
        end
      end
    rescue Protocol::HTTP2::StreamClosed, IOError, EOFError => e
      raise Error, "Request failed: #{e.message}" if retried

      @client = Async::HTTP::Client.new(@endpoint)
      get path, retried: true, **params
    end

    # Seconds to wait before retrying a 429. Honors a server-provided
    # Retry-After header (in seconds) when present; otherwise falls back to
    # exponential backoff (retry_wait * 2**retries), capped at MAX_RETRY_WAIT.
    def retry_delay(response, retries)
      header = response.headers["retry-after"]
      header = header.first if header.is_a?(Array)
      seconds = header.to_f if header
      seconds = @retry_wait * (2**retries) unless seconds&.positive?

      [seconds, MAX_RETRY_WAIT].min
    end
  end
end
