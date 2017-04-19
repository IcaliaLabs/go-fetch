require 'byebug'

class GoFetch < Thor
  option :github
  option :user
  option :password
  option :treeish

  desc "checkout [OPTIONS] WORKTREE [TREEISH]", "Performs a checkout of code in the given worktree"
  method_option :fetch, type: :boolean
  method_option :prune, type: :boolean
  def checkout(worktree_name, treeish = nil)
    with_exit_code = 0
    fetch_from_origin if !!options[:fetch]
    checkout_worktree worktree_name, treeish
    JSON.dump last_commit_data(treeish), STDOUT
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
    def checkout_worktree(worktree_name, treeish = nil)
      treeish ||= options[:treeish]
      worktree_path = Pathname.new File.join('/', worktree_name)
      FileUtils.rm_rf worktree_path
      local_repo.add_worktree worktree_path, treeish
    end

    def last_commit_data(treeish = nil)
      treeish ||= options[:treeish]
      last_commit = local_repo.gtree(treeish).log(1).last
      last_commit_data = {
        sha: last_commit.sha,
        author_name: last_commit.author.name,
        author_email: last_commit.author.email,
        message: last_commit.message
      }
      last_commit_data[:parent_sha] = last_commit.parent.sha if !!last_commit.parent
      last_commit_data
    end
  end
end
