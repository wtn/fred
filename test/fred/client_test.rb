# frozen_string_literal: true

require_relative "../test_helper"

describe FRED::Client do
  it "initializes with api_key" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be_a(FRED::Client)
  end

  it "reads api_key from environment variable" do
    ENV["FRED_API_KEY"] = TEST_API_KEY
    client = FRED::Client.new
    expect(client).to be_a(FRED::Client)
  ensure
    ENV.delete("FRED_API_KEY")
  end

  it "raises ArgumentError when api_key is missing" do
    ENV.delete("FRED_API_KEY")
    expect do
      FRED::Client.new(api_key: nil)
    end.to raise_exception(ArgumentError, message: be =~ /API key/)
  end

  it "validates api_key format" do
    expect do
      FRED::Client.new(api_key: "too_short")
    end.to raise_exception(ArgumentError, message: be =~ /32-character lowercase hex/)
  end

  it "rejects uppercase api_key" do
    expect do
      FRED::Client.new(api_key: "ABCDEF01234567890ABCDEF012345678")
    end.to raise_exception(ArgumentError, message: be =~ /32-character lowercase hex/)
  end

  it "has series method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :series)
  end

  it "has series_observations method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :series_observations)
  end

  it "has series_search method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :series_search)
  end

  it "has category method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :category)
  end

  it "has releases method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :releases)
  end

  it "has release_dates method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :release_dates)
  end

  it "has releases_dates method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :releases_dates)
  end

  it "has sources method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :sources)
  end

  it "has tags method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :tags)
  end

  it "has close method" do
    client = FRED::Client.new(api_key: TEST_API_KEY)
    expect(client).to be(:respond_to?, :close)
  end
end
