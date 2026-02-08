# frozen_string_literal: true

require_relative "../test_helper"
require "sus/fixtures/async/http/server_context"

describe "429 retry behavior" do
  include Sus::Fixtures::Async::HTTP::ServerContext

  SERIES_JSON = {
    "seriess" => [{
      "id" => "GNPCA",
      "title" => "Real Gross National Product",
      "observation_start" => "1929-01-01",
      "observation_end" => "2023-01-01",
      "frequency" => "Annual",
      "frequency_short" => "A",
      "units" => "Billions of Chained 2017 Dollars",
      "units_short" => "Bil. of Chn. 2017 $",
      "seasonal_adjustment" => "Not Seasonally Adjusted",
      "seasonal_adjustment_short" => "NSA",
      "last_updated" => "2024-03-28 07:56:03-05",
      "popularity" => 16,
    }],
  }.freeze

  ERROR_429_JSON = {
    "error_code" => 429,
    "error_message" => "Too Many Requests.  Exceeded Rate Limit",
  }.freeze

  ERROR_500_JSON = {
    "error_code" => 500,
    "error_message" => "Internal Server Error",
  }.freeze

  def json_headers
    [["content-type", "application/json; charset=UTF-8"]]
  end

  describe "retries on 429 then succeeds" do
    let(:request_count) { Async::Variable.new }

    def app
      count = 0
      Protocol::HTTP::Middleware.for do |request|
        count += 1
        if count <= 2
          Protocol::HTTP::Response[429, json_headers, [JSON.generate(ERROR_429_JSON)]]
        else
          Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
        end
      end
    end

    it "retries and returns data" do
      client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
        retry_wait: 0.01,
      )
      s = client.series series_id: "GNPCA"
      expect(s).to be_a(FRED::Series)
      expect(s.id).to be == "GNPCA"
    end
  end

  describe "survives more than three consecutive 429s" do
    def app
      count = 0
      Protocol::HTTP::Middleware.for do |request|
        count += 1
        if count <= 4
          Protocol::HTTP::Response[429, json_headers, [JSON.generate(ERROR_429_JSON)]]
        else
          Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
        end
      end
    end

    it "keeps retrying past the old three-retry cap" do
      client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
        retry_wait: 0.01,
      )
      s = client.series series_id: "GNPCA"
      expect(s.id).to be == "GNPCA"
    end
  end

  describe "honors the Retry-After header" do
    def app
      count = 0
      Protocol::HTTP::Middleware.for do |request|
        count += 1
        if count == 1
          Protocol::HTTP::Response[
            429,
            json_headers + [["retry-after", "1"]],
            [JSON.generate(ERROR_429_JSON)],
          ]
        else
          Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
        end
      end
    end

    it "waits the server-specified interval before retrying" do
      # retry_wait is tiny; if Retry-After were ignored the retry would be
      # near-instant. A ~1s elapsed time proves the header was honored.
      client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
        retry_wait: 0.01,
      )
      elapsed = Async::Clock.measure do
        client.series series_id: "GNPCA"
      end
      expect(elapsed).to be >= 0.9
    end
  end

  describe "gives up after max retries" do
    def app
      Protocol::HTTP::Middleware.for do |request|
        Protocol::HTTP::Response[429, json_headers, [JSON.generate(ERROR_429_JSON)]]
      end
    end

    it "raises Error with API message after exhausting retries" do
      client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
        retry_wait: 0.01,
      )
      expect do
        client.series series_id: "GNPCA"
      end.to raise_exception(FRED::Error, message: be =~ /Too Many Requests/)
    end
  end

  describe "does not retry non-429 errors" do
    def app
      count = 0
      Protocol::HTTP::Middleware.for do |request|
        count += 1
        if count == 1
          Protocol::HTTP::Response[500, json_headers, [JSON.generate(ERROR_500_JSON)]]
        else
          Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
        end
      end
    end

    it "raises immediately on 500" do
      client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
        retry_wait: 0.01,
      )
      expect do
        client.series series_id: "GNPCA"
      end.to raise_exception(FRED::Error, message: be =~ /Internal Server Error/)
    end
  end

  describe "includes API error message in exceptions" do
    def app
      Protocol::HTTP::Middleware.for do |request|
        Protocol::HTTP::Response[400, json_headers, [JSON.generate(
          "error_code" => 400,
          "error_message" => "Bad Request.  Variable series_id is not set.",
        )]]
      end
    end

    it "parses error_message from response body" do
      client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
      )
      expect do
        client.series series_id: "FAKE"
      end.to raise_exception(FRED::Error, message: be =~ /Bad Request.*series_id/)
    end
  end
end
