require 'json'
require_relative '../lib/code_location'

class GoFetch < Thor
  option :github
  option :user
  option :password
  option :treeish

  desc "extract [OPTIONS] LOCATION_1, [LOCATION_2, ...]", "Extracts contents from the given locations"
  method_option :fetch, type: :boolean
  method_option :prune, type: :boolean
  def extract(*locations)
    with_exit_code = 0
    fetch_from_origin if !!options[:fetch]
    treeish = options[:treeish] ||= 'origin/master'

    STDOUT.print '['
    locations.each_with_index do |location_string, index|
      fragment = extract_fragment_from treeish, CodeLocation.from_string(location_string)
      extraction = { location_string => fragment }
      JSON.dump extraction, STDOUT
      STDOUT.print ',' if index < (locations.size - 1)
    end
    STDOUT.print ']'
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
    def extract_fragment_from(treeish, loc)
      body = local_repo.show treeish, loc.path
      return body unless loc.fragment?
      body_lines = body.split "\n"
      return body_lines[loc.line_index_range].join("\n") if loc.line_range?
      body_lines[loc.begin_line_index]
    rescue Git::GitExecuteError => git_error
      return if git_error.message["Path '#{loc.path}' does not exist in '#{treeish}'"]
      raise git_error
    end
  end
end
