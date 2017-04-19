require 'byebug'

class GoFetch < Thor
  option :github
  option :user
  option :password

  desc "fetch [OPTIONS]", "Fetches the changes/code from a remote repo into the repos library"
  method_option :prune, type: :boolean
  def fetch
    with_exit_code = 0
    fetch_from_origin
    result = { status: 'OK' }
    JSON.dump result, STDOUT
  rescue => run_error
    result = {
      error_class: run_error.class.name,
      error_message: run_error.message,
      error_backtrace: run_error.backtrace
    }
    JSON.dump result, STDERR
    with_exit_code = 666
  ensure
    STDOUT.puts
    exit with_exit_code
  end

  no_commands do
    def fetch_from_origin
      origin.set_url github_repo_uri_with_credentials
      origin.fetch prune: !!options[:prune]
    ensure
      origin.set_url github_repo_uri
    end

    def repo_uri
      return github_repo_uri if options.key?(:github)
    end

    def github_repo_uri
      URI("https://github.com/#{options[:github]}.git")
    end

    def github_repo_uri_with_credentials
      github_repo_uri.tap do |uri|
        uri.user     = options[:user]     if options.key? :user
        uri.password = options[:password] if options.key? :password
      end
    end

    def repo_path
      return github_repo_path if options.key? :github
    end

    def github_repo_path
      Pathname.new File.join('/', 'repos', 'github.com', options[:github])
    end

    def local_repo
      return Git.open(repo_path, bare: true) if repo_path.exist?
      Git.init(repo_path, bare: true)
    end

    def origin
      origin_remote = local_repo.remotes.detect { |remote| remote.name == 'origin' }
      return local_repo.add_remote(:origin, github_repo_uri) unless !!origin_remote
      origin_remote
    end
  end
end
