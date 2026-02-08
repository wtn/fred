# frozen_string_literal: true

require "date"
require "json"
require "timeseries"

require_relative "fred/version"
require_relative "fred/client"

module FRED
  class Error < StandardError; end

  API_KEY_PATTERN = /\A[0-9a-f]{32}\z/

  class << self
    def client
      @client ||= Client.new
    end

    def reset_client!
      @client&.close
      @client = nil
    end

    def series(...) = client.series(...)
    def series_observations(...) = client.series_observations(...)
    def series_search(...) = client.series_search(...)
    def series_categories(...) = client.series_categories(...)
    def series_release(...) = client.series_release(...)
    def series_tags(...) = client.series_tags(...)
    def series_updates(...) = client.series_updates(...)

    def category(...) = client.category(...)
    def category_children(...) = client.category_children(...)
    def category_series(...) = client.category_series(...)
    def category_tags(...) = client.category_tags(...)

    def releases(...) = client.releases(...)
    def release(...) = client.release(...)
    def release_dates(...) = client.release_dates(...)
    def release_series(...) = client.release_series(...)
    def releases_dates(...) = client.releases_dates(...)

    def sources(...) = client.sources(...)
    def source(...) = client.source(...)
    def source_releases(...) = client.source_releases(...)

    def tags(...) = client.tags(...)
    def tags_series(...) = client.tags_series(...)
  end

  Series = Data.define(
    :id, :title,
    :observation_start, :observation_end,
    :frequency, :frequency_short,
    :units, :units_short,
    :seasonal_adjustment, :seasonal_adjustment_short,
    :last_updated, :popularity, :notes,
  ) do
    def self.parse(row)
      new(
        id: row["id"],
        title: row["title"],
        observation_start: row["observation_start"],
        observation_end: row["observation_end"],
        frequency: row["frequency"],
        frequency_short: row["frequency_short"],
        units: row["units"],
        units_short: row["units_short"],
        seasonal_adjustment: row["seasonal_adjustment"],
        seasonal_adjustment_short: row["seasonal_adjustment_short"],
        last_updated: row["last_updated"],
        popularity: row["popularity"],
        notes: row["notes"],
      )
    end
  end

  Category = Data.define(:id, :name, :parent_id) do
    def self.parse(row)
      new(
        id: row["id"],
        name: row["name"],
        parent_id: row["parent_id"],
      )
    end
  end

  Release = Data.define(:id, :name, :press_release, :link) do
    def self.parse(row)
      new(
        id: row["id"],
        name: row["name"],
        press_release: row["press_release"],
        link: row["link"],
      )
    end
  end

  Source = Data.define(:id, :name, :link, :notes) do
    def self.parse(row)
      new(
        id: row["id"],
        name: row["name"],
        link: row["link"],
        notes: row["notes"],
      )
    end
  end

  ReleaseDate = Data.define(:release_id, :release_name, :date) do
    def self.parse(row)
      new(
        release_id: row["release_id"],
        release_name: row["release_name"],
        date: Date.parse(row["date"]),
      )
    end
  end

  Tag = Data.define(:name, :group_id, :notes, :created, :popularity, :series_count) do
    def self.parse(row)
      new(
        name: row["name"],
        group_id: row["group_id"],
        notes: row["notes"],
        created: row["created"],
        popularity: row["popularity"],
        series_count: row["series_count"],
      )
    end
  end
end
