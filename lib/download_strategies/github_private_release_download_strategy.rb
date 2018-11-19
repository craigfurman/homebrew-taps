# frozen_string_literal: true

# TODO hacky experiment
require "bundler"
Bundler.load
require "octokit"

module DownloadStrategies
  class GithubPrivateReleaseDownloadStrategy < AbstractFileDownloadStrategy
    def fetch
      client = Octokit::Client.new(access_token: ENV.fetch("HOMEBREW_GITHUB_API_TOKEN"))

      asset_url = client.releases("gocardless/#{name}").
        detect { |rel| rel.name == "v#{version}" }.
        assets.detect { |asset| asset.name.include?("darwin_amd64") }.url

      # This is poor. The asset will often be large, so we should really stream it to
      # disk. The octokit ruby library doesn't support this, so I've taken the lazy route
      # and simply buffered it in memory. Ensure your laptop has a spare 14MB of RAM to
      # install anu.
      asset_bytes = client.get(asset_url, accept: "application/octet-stream")
      File.write(temporary_path, asset_bytes)
    end
  end
end
