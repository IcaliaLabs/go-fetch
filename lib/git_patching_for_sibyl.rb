require 'git'

#= Git (patching for sibyl)
#
# Patches applied to the git / git-ng gem to add missing functionality, specially the functions used
# by the Sibyl code fetcher.
#
# Until https://github.com/libgit2/rugged supports git worktrees
# (See https://github.com/libgit2/rugged/issues/694), this is what we'll depend on for our code
# fecther service.
module Git
  #= Git::Base (patching for sibyl)
  #
  # Overrides to the Git::Base class to add missing functionality
  class Base
    def add_worktree(path, branch_or_treeish = nil, opts = {})
      lib.worktree_add path, branch_or_treeish, opts
      Worktree.new self, path, branch_or_treeish
    end

    def unlock_worktree(path)
      lib.worktree_unlock path
    end

    def prune_worktrees(opts = {})
      lib.worktree_prune opts
    end

    def worktree?(worktree_path)
      worktrees.key? worktree_path.to_s
    end

    #= Git::Base::Factory (patching for sibyl)
    #
    # Overrides to the Git::Base::Factory class to spawn a list of worktrees from a repo
    module Factory
      def worktrees
        Git::Worktrees.new self
      end
    end
  end

  #= Git::Lib (patching for sibyl)
  #
  # Overrides to the Git::Lib class to add missing functionality
  class Lib
    def remote_set_url(name, url, old_url = nil, opts = {})
      arr_opts = ['set-url']
      arr_opts << '--add' if opts[:add]
      arr_opts << '--push' if opts[:push]
      arr_opts << '--delete' if opts[:delete]
      arr_opts << name
      arr_opts << url
      arr_opts << old_url if old_url.present?

      command 'remote', arr_opts
    end

    def worktree_add(path, branch = nil, opts = {})
      arr_opts = ['add']
      arr_opts << '-f' if opts[:f] || opts[:force]
      arr_opts << '--detach' if opts[:detach]
      arr_opts << '--checkout' if opts[:checkout]
      arr_opts << '-b' << opts[:new_branch] if opts[:new_branch] && opts[:new_branch] != ''
      arr_opts << path
      arr_opts << branch if branch && branch != ''

      command 'worktree', arr_opts
    end

    def worktree_list(opts = {})
      arr_opts = ['list']
      arr_opts << '--porcelain' if opts[:porcelain]

      command 'worktree', arr_opts
    end

    def worktree_lock(path, opts = {})
      arr_opts = ['lock']
      arr_opts << '--reason' << opts[:reason] if opts[:reason].present?
      arr_opts << path

      command 'worktree', arr_opts
    end

    def worktree_prune(opts = {})
      arr_opts = ['prune']
      arr_opts << '--dry-run' if opts[:n] || opts[:dry_run]
      arr_opts << '--verbose' if opts[:v] || opts[:verbose]
      arr_opts << '--expire' << opts[:expire] if opts[:expire].present?

      command 'worktree', arr_opts
    end

    def worktree_unlock(path)
      arr_opts = ['unlock']
      arr_opts << path

      command 'worktree', arr_opts
    end
  end

  #= Git::Remote (patching for sibyl)
  #
  # Overrides to the Git::Remote class to add the missing `git remote set-url` functionality
  class Remote < Path
    def set_url(url, old_url = nil, opts = {})
      @base.lib.remote_set_url(@name, url, old_url, opts)
    end
  end

  #= Git::Worktree
  #
  # Represents a Git worktree
  class Worktree < Base
    attr_reader :path, :treeish

    def initialize(given_base, working_dir, given_treeish = nil)
      @base = given_base
      @path = working_dir
      @treeish = given_treeish

      super working_directory: @path,
            log: @base.instance_variable_get(:@logger),
            repository: @base.instance_variable_get(:@repository).path
    end

    def lock(opts = {})
      @base.lib.worktree_lock(@path, opts)
      true
    end

    def unlock
      @base.lib.worktree_unlock(@path)
    end

    def ls
      @base.gtree(treeish).full_tree.map { |leaf| leaf.split("\t").last }
    end
  end

  #= Git::Worktrees
  #
  # Represents the list of worktrees spawned from a repo
  class Worktrees
    include Enumerable

    def initialize(base)
      @worktrees = {}

      base.lib.worktree_list.split("\n").each do |line|
        workdir = line.split.first
        @worktrees[workdir] = Git::Worktree.new base, workdir if workdir.present?
      end
    end

    # array like methods

    def size
      @worktrees.size
    end

    def each(&block)
      @worktrees.values.each(&block)
    end

    def key?(path)
      @worktrees.key? path.to_s
    end

    def [](path)
      @worktrees[path.to_s]
    end
  end
end
