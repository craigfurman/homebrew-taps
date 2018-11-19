# frozen_string_literal: true

# Not even a monkey patch, but arguably even worse. This declaration doesn't overwrite any
# other loaded class in the rspec runtime $LOAD_PATH, but it will be declared by Homebrew
# when this tap is used.
# The GithubPrivateReleaseDownloadStrategy will need to inherit from it, so we build a
# handrolled mock here
class AbstractFileDownloadStrategy
  def temporary_path
    "/some/temporary/path"
  end

  def name
    "a-repo"
  end

  def version
    "1.2.3"
  end
end

# Stubs
Asset = Struct.new(:name) do
  def url
    "url-for-#{name}"
  end
end
Release = Struct.new(:name) do
  def assets
    ["not this one", "this_one_darwin_amd64.tar.gz", "also not this one"].map do |name|
      Asset.new(name)
    end
  end
end

require "download_strategies/github_private_release_download_strategy"

# TODO apologise and explain how DI is impossible in a brew context
RSpec.describe DownloadStrategies::GithubPrivateReleaseDownloadStrategy do
  subject(:strategy) { described_class.new }

  let(:github_token) { "a-token" }
  let(:github_client) { instance_double(Octokit::Client) }
  # By default Github releases are named after the release tag. We don't change this.
  let(:releases) { ["foo", "v1.2.3", "bar"].map { |name| Release.new(name) } }
  let(:asset_content) { "a poor substitute for a byte array" }

  before do
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = github_token
  end

  it "downloads the asset to a location provided by the Homebrew base class" do
    expect(Octokit::Client).to receive(:new).with(access_token: github_token).
      and_return(github_client)

    expect(github_client).to receive(:releases).with("gocardless/a-repo").
      and_return(releases)

    expect(github_client).to receive(:get).
      with("url-for-this_one_darwin_amd64.tar.gz", accept: "application/octet-stream").
      and_return(asset_content)

    expect(File).to receive(:write).with("/some/temporary/path", asset_content)

    # Start the mock trainwreck
    strategy.fetch
  end
end
