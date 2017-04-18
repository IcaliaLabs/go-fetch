require 'json'

class GoFetch < Thor
  option :github
  option :user
  option :password

  desc "extract [OPTIONS] WORKTREE_NAME TREEISH LOCATION_1, [LOCATION_2, ...]", "say hello to checkout"
  def extract(worktree_name, treeish, *locations)
    worktree_path = Pathname.new File.join('/', worktree_name)
    repo_uri = extract_repo_uri_with_credentials
    repo_path = extract_repo_path_from repo_uri
    repo = get_local_repo repo_path
    checkout_worktree repo, repo_uri, worktree_path, treeish

    STDOUT.print '['
    locations.each_with_index do |location_string, index|
      fragment = extract_fragment_from worktree_path, CodeLocation.from_string(location_string)
      extraction = { location_string => fragment }
      JSON.dump extraction, STDOUT
      STDOUT.print ',' if index < (locations.size - 1)
    end
    STDOUT.puts ']'
  ensure
    repo.remotes.map(&:remove)
  end

  #= CodeLocation
  #
  # Value-Object model that helps us defining locations over code :)
  class CodeLocation
    attr_reader :path, :begin_line, :begin_column, :end_line, :end_column, :offset

    # Form 1: With Offset
    # - path
    # - offset
    # Form 2: With begin/end (+ offset - compatible to use with ActiveRecord `composed_of`)
    # - path
    # - begin_line
    # - begin_column
    # - end_line
    # - end_column
    # - offset
    def initialize(given_path, offset_or_begin_line = nil, *args)
      @path, @data = given_path, {}
      if args.empty?
        @data[:offset] = offset_or_begin_line
      else
        @data[:begin_line] = offset_or_begin_line
        @data[:begin_column], @data[:end_line], @data[:end_column], @data[:offset] = args
      end
    end

    define_method(:begin_line) { @data[:begin_line].to_i if @data[:begin_line] }
    define_method(:begin_column) { @data[:begin_column].to_i if @data[:begin_column] }
    define_method(:end_line) { @data[:end_line].to_i if @data[:end_line] }
    define_method(:end_column) { @data[:end_column].to_i if @data[:end_column] }
    define_method(:offset) { @data[:offset].to_i if @data[:offset] }

    def inspect
      return "<CodeLocation #{path}:#{offset}" if offset.present?
      loc_begin = "L#{begin_line}"
      loc_end = "L#{end_line}"
      loc_begin << "C#{begin_column}" if begin_column
      loc_end << "C#{end_column}" if end_column
      "<CodeLocation #{path}:#{loc_begin}..#{loc_end}>"
    end

    def ==(other)
      # NOTE: It is intended for a code location to be equal regardless of the actual contents of said
      # range/section/whatever:
      [:path, :begin_line, :begin_column, :end_line, :end_column, :offset]
        .map { |attr_name| send(attr_name) == other.send(attr_name) }
        .reduce(:&)
    end

    def fragment?
      (begin_line || end_line || offset)
    end

    def line_range
      return begin_line..end_line if begin_line && end_line
    end

    def as_array_slice
      return (fragment_range.begin - 1)..(fragment_range.end - 1) if (fragment_range = line_range)
      (begin_line || end_line) - 1
    end

    STRING_MATCHER = /^L(?<begin_line>\d+)(C(?<begin_column>\d+))?((-|\.{2})L(?<end_line>\d+)(C(?<end_column>\d+))?)?/

    def self.from_string(string)
      path, range_string = string.split ':'
      return new path unless range_string
      sel = STRING_MATCHER.match range_string
      new path, sel[:begin_line], sel[:begin_column], sel[:end_line], sel[:end_column]
    end
  end


  no_commands do
    def extract_fragment_from(worktree_path, loc)
      path = worktree_path.join(loc.path)
      return nil unless path.exist?
      return File.read path unless loc.fragment?
      contents = File.readlines(path)
      return contents[((loc.begin_line || loc.end_line) - 1)] unless (fragment = loc.line_range)
      contents[(fragment.begin - 1)..(fragment.end - 1)].join
    end

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
