require 'minitest/autorun'
require 'minitest/mock'
require 'shoulda-context'
require 'multi_xml'
require 'fred'

def fixture_file(filename)
  return '' if filename.empty?
  file_path = File.expand_path(File.join('fixtures', filename), __dir__)
  File.read(file_path)
end

FakeResponse = Struct.new(:code, :parsed_response)

def stub_request(fixture_filename)
  parsed = MultiXml.parse(fixture_file(fixture_filename))
  response = FakeResponse.new(200, parsed)
  ->(_path, _options = {}) { response }
end
