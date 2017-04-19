require 'json'

class GoFetch < Thor
  option :github
  option :user
  option :password
  option :treeish

  desc "list_files [OPTIONS] [TREEISH]", "lists the files in a tree-ish"
  method_option :fetch, type: :boolean
  method_option :prune, type: :boolean
  def list_files(treeish = nil)
    with_exit_code = 0
    fetch_from_origin if !!options[:fetch]
    JSON.dump list_treeish_files(treeish), STDOUT
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
    def list_treeish_files(treeish = nil)
      treeish ||= options[:treeish]
      local_repo.gtree(treeish).full_tree.map { |leaf| leaf.split("\t").last }
    end
  end
end
