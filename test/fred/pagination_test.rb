# frozen_string_literal: true

require_relative "../test_helper"
require "sus/fixtures/async/http/server_context"

describe "auto-pagination" do
  include Sus::Fixtures::Async::HTTP::ServerContext

  ALL_SERIES = (1..3).map { |i|
    {
      "id" => "S#{i}",
      "title" => "Series #{i}",
      "observation_start" => "2020-01-01",
      "observation_end" => "2024-01-01",
      "frequency" => "Annual",
      "frequency_short" => "A",
      "units" => "Units",
      "units_short" => "U",
      "seasonal_adjustment" => "Not Seasonally Adjusted",
      "seasonal_adjustment_short" => "NSA",
      "last_updated" => "2024-01-01 00:00:00-05",
      "popularity" => 50,
      "notes" => "Notes #{i}",
    }
  }.freeze

  ALL_OBSERVATIONS = (1..5).map { |i|
    { "date" => "202#{i}-01-01", "value" => "#{100 + i}.0" }
  }.freeze

  ALL_TAGS = (1..4).map { |i|
    {
      "name" => "tag#{i}",
      "group_id" => "gen",
      "notes" => "Tag #{i}",
      "created" => "2012-02-27 10:18:19-06",
      "popularity" => 100 - i,
      "series_count" => 1000 - i,
    }
  }.freeze

  def json_headers
    [["content-type", "application/json; charset=UTF-8"]]
  end

  # Simulate a server that caps pages at max_per_page items
  def paginate(all_items, key, params, max_per_page: 2)
    offset = (params["offset"] || 0).to_i
    limit = [(params["limit"] || 1000).to_i, max_per_page].min
    page = all_items[offset, limit] || []

    body = {
      "count" => all_items.length,
      "offset" => offset,
      "limit" => limit,
      key => page,
    }

    Protocol::HTTP::Response[200, json_headers, [JSON.generate(body)]]
  end

  def parse_params(request)
    query = request.path.split("?", 2).last
    URI.decode_www_form(query).to_h
  end

  def app
    Protocol::HTTP::Middleware.for do |request|
      path = request.path.split("?").first
      params = parse_params(request)

      case path
      when "/fred/series/search"
        paginate(ALL_SERIES, "seriess", params)
      when "/fred/series/observations"
        paginate(ALL_OBSERVATIONS, "observations", params)
      when "/fred/tags"
        paginate(ALL_TAGS, "tags", params)
      else
        Protocol::HTTP::Response[404, json_headers, ["{}"]]
      end
    end
  end

  let(:fred) do
    FRED::Client.new(
      api_key: TEST_API_KEY,
      endpoint: client_endpoint,
      rate_limit: false,
    )
  end

  describe "series_search returns all results across pages" do
    it "fetches all 3 series despite server page size of 2" do
      results = fred.series_search search_text: "test"
      expect(results.length).to be == 3
      expect(results.map(&:id)).to be == %w[S1 S2 S3]
    end
  end

  describe "series_observations returns all results across pages" do
    it "fetches all 5 observations despite server page size of 2" do
      ts = fred.series_observations series_id: "TEST"
      expect(ts.size).to be == 5
      expect(ts["TEST"]).to be == [101.0, 102.0, 103.0, 104.0, 105.0]
    end
  end

  describe "tags returns all results across pages" do
    it "fetches all 4 tags despite server page size of 2" do
      tags = fred.tags
      expect(tags.length).to be == 4
      expect(tags.map(&:name)).to be == %w[tag1 tag2 tag3 tag4]
    end
  end

  describe "limit caps total results" do
    it "returns at most limit items" do
      results = fred.series_search search_text: "test", limit: 2
      expect(results.length).to be == 2
      expect(results.map(&:id)).to be == %w[S1 S2]
    end
  end

  describe "explicit offset skips auto-pagination" do
    it "returns one server page, not all remaining items" do
      ts = fred.series_observations series_id: "TEST", offset: 1
      # Server page size is 2, 4 items remain from offset 1.
      # Without single-page behavior, auto-pagination would return all 4.
      expect(ts.size).to be == 2
      expect(ts["TEST"]).to be == [102.0, 103.0]
    end

    it "respects limit as page size" do
      results = fred.series_search search_text: "test", offset: 0, limit: 2
      expect(results.length).to be == 2
      expect(results.map(&:id)).to be == %w[S1 S2]
    end
  end

  describe "single page when all results fit" do
    it "does not over-fetch" do
      results = fred.series_search search_text: "test"
      expect(results.length).to be == 3
    end
  end
end
