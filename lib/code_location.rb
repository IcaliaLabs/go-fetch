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

  def to_s
    return "#{path}:O#{offset}" if offset?
    range = begin? ? self.class.line_column_string(begin_line, begin_column) : ''
    range << "..#{self.class.line_column_string(end_line, end_column)}" if end?
    return path unless range != ''
    "#{path}:#{range}"
  end

  def begin?
    !!begin_line
  end

  def end?
    !!end_line
  end

  def offset?
    !!offset
  end

  def self.line_column_string(line, column = nil)
    begin_s = "L#{line}"
    begin_s << "C#{column}" if !!column
    begin_s
  end

  def inspect
    "<CodeLocation #{to_s}>"
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

  def line_range?
    begin_line && end_line
  end

  def line_range
    return unless line_range?
    top    = begin_line.to_i # if it's nil, will go to zero
    bottom = end_line || -1  # If it's nil, will go to -1
    top..bottom
  end

  def line_index_range
    return unless range = line_range
    (range.begin - 1)..(range.end - 1)
  end

  def begin_line_index
    index = begin_line.to_i - 1
    return 0 if index < 0
    index
  end

  STRING_MATCHER = /^(L(?<begin_line>\d+)(C(?<begin_column>\d+))?)?((-|\.{2})L(?<end_line>\d+)(C(?<end_column>\d+))?)?/

  def self.from_string(string)
    path, range_string = string.split ':'
    return new path unless range_string
    sel = STRING_MATCHER.match range_string
    new path, sel[:begin_line], sel[:begin_column], sel[:end_line], sel[:end_column]
  end
end
