require 'byebug'

class GoFetch < Thor
  option :github
  option :user
  option :password

  desc "checkout [OPTIONS] WORKTREE_NAME TREEISH", "say hello to checkout"
  def checkout(worktree_name, treeish)
    worktree_path = Pathname.new File.join('/', worktree_name)
    repo_uri = extract_repo_uri_with_credentials
    repo_path = extract_repo_path_from repo_uri
    repo = get_local_repo repo_path
    checkout_worktree repo, repo_uri, worktree_path, treeish
    checkout_data = { treeish: treeish, commit_sha: repo.gtree(treeish).log(1).last.sha }
    JSON.dump checkout_data, STDOUT
    STDOUT.puts
  ensure
    repo.remotes.map(&:remove)
  end

  no_commands do
    def checkout_worktree(repo, repo_uri, worktree_path, treeish)
      cleanup_workdir repo, worktree_path
      fetch_and_prune repo, repo_uri
      repo.add_worktree worktree_path, treeish
    end

    def cleanup_workdir(repo, destination)
      FileUtils.rm_rf destination
    end

    def fetch_and_prune(repo, repo_uri)
      origin = repo.add_remote :origin, repo_uri
      origin.fetch prune: true
    end

    def extract_repo_uri_with_credentials
      return extract_github_repo_uri if options.key?(:github)
    end

    def extract_github_repo_uri
      URI("https://github.com/#{options[:github]}.git").tap do |uri|
        uri.user     = options[:user]     if options.key? :user
        uri.password = options[:password] if options.key? :password
      end
    end

    def extract_repo_path_from(repo_uri)
      path = repo_uri.path
      extension = File.extname(path)
      full_path = File.join('/', 'repos', repo_uri.host, *path.gsub(extension, '')[1..-1].split('/'))
      Pathname.new full_path
    end

    def get_local_repo(repo_path)
      return Git.open(repo_path, bare: true) if repo_path.exist?
      Git.init(repo_path, bare: true)
    end
  end
end
