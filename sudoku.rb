#!/usr/bin/env ruby

require 'set'

# A cell respresents a single location on the sudoku board.  Initially
# it holds no number, but a number can be manually assigned to the
# cell (which is then remembered for later).
#
# Each cell also belongs to 3 groups of cells, (1) the cells in its
# vertical column, (2) horizontal row, and (3) the 3x3 block of
# neighboring cells.  By looking at the cells in each of the groups,
# an individual cell can report on the list of possible numbers that
# are available for assignment to the cell. (If a cell already has an
# assigned number, the set of available numbers is empty).
#
class Cell
  attr_reader :number

  OneThruNine = Set[*1..9]

  # Initialize a cell with the name :name.
  def initialize(name="unamed")
    @name = name
    @groups = []
  end

  # Assign a number to the cell.  Assigning nil or 0 leaves the cell
  # unassigned.
  def number=(value)
    @number = value.nonzero?
  end

  # Is the cell unassigned?
  def unassigned?
    number.nil?
  end

  # Return a set of numbers that could be assigned to the cell without
  # conflicting with any cells in any of the cell's groups.
  def available_numbers
    if number
      Set[]
    else
      @groups.inject(OneThruNine) { |res, group|
        res - group.numbers
      }
    end
  end

  # The cell joins the given group.
  def join(group)
    @groups << group
  end

  # Provide a string representation of the cell.
  def to_s
    @name
  end

  # Provided an inspect string for the cell.
  def inspect
    to_s
  end
end


# Cells are organized into groups.  Each group consists of 9 cells
# where the number assigned to a cell must be unique within the group.
# Groups are able to report the current set of assigned numbers within
# the group.
class Group

  # Initialize a group.
  def initialize
    @cells = []
  end

  # Add a cell to the given group.  Make sure the cell knows that it
  # has joined the group.
  def <<(cell)
    cell.join(self)
    @cells << cell
    self
  end

  # Return a set of numbers assigned to the cells in this group.
  def numbers
    Set[*@cells.map { |c| c.number }.compact]
  end

  # Set of open (i.e. unassigned) numbers in this group.
  def open_numbers
    Set[1,2,3,4,5,6,7,8,9] - numbers
  end

  # Set of open cells that could possibly hold the given number.
  def cells_open_for(number)
    Set[*@cells.select { |cell| cell.available_numbers.include?(number) }]
  end

  # Map of all open numbers to their open cells.
  def open_cells_map
    open_numbers.inject({}) { |h, n| h.merge(n => cells_open_for(n)) }
  end

end

# A Sudoku board contains the 81 cells required by the puzzle.  The
# groupings of the cells is specified by the board in the
# :define_groups method.  The standard grouping is 9 row groups, 9
# column groups and 9 3x3 groups.
#
class Board
  SudokuError = Class.new(StandardError)
  ParseError = Class.new(SudokuError)
  SolutionError = Class.new(SudokuError)

  attr_reader :cells, :groups
  attr_writer :strategies

  # Initialize a board with a set of unassigned cells.
  def initialize(verbose=nil)
    @verbose = verbose
    @cells = (0...81).map { |i|
      Cell.new("C#{(i/9)+1}#{(i%9)+1}")
    }
    @groups = define_groups
  end

  def strategies
    @strategies ||=
      [CellStrategy, GroupStrategy, BacktrackingStrategy].map { |sc| sc.new(self) }
  end

  # Parse an encoded puzzle string.  Spaces or periods ('.') are
  # treated as unassigned cells.  Newlines and tabs are ignored.
  def parse(string)
    clean_string = clean(string)
    fail ParseError, "Puzzle encoding too short" if clean_string.size < 81
    fail ParseError, "Puzzle encoding too long" if clean_string.size > 81
    fail ParseError, "Puzzle contains invalid characters" if clean_string !~ /^[ .0-9]+$/
    numbers = clean_string.split(//).map { |n| n.to_i }
    cells.each do |cell|
      cell.number = numbers.shift
    end
    self
  end

  def clean(string)
    string.gsub(/^#.*$/, '').gsub(/[\r\n\t]/, '')
  end
  private :clean

  # Has the puzzle been solved?  In other words, have all the cells
  # been assigned numbers?
  def solved?
    cells.all? { |cell| cell.number }
  end

  # Are we stuck?  In other words, is there an unassigned cell where
  # there are no available numbers to be assigned to it.
  def stuck?
    cells.any? { |cell| cell.unassigned? && cell.available_numbers.size == 0 }
  end

  # Provide a human readable version of the board in a grid format.
  def to_s
    encoding.
      gsub(/.../, "\\0 ").
      gsub(/.{12}/, "\\0\n").
      gsub(/.{39}/m, "\\0\n").
      gsub(/[\d.]/, "\\0 ")
  end

  # Provide a inspect string for a board.
  def inspect
    "<Board #{encoding}>"
  end

  # Encode the board into an 81 character string.  Each character
  # represents the number stored in each cell.  Unassigned cells are
  # represented by a '.'.  Cells are ordered starting in the upper
  # left corner and sweeping first left to right across the row, and
  # then each successive row.
  def encoding
    cells.map { |cell| cell.number || "." }.join
  end

  # Solve the puzzle represented by the board. Try each of the
  # solution strategies until the puzzle is solved or the solutions
  # are unable to make any progress.
  def solve
    while ! solved?
      unless strategies.find { |s| s.solve }
        fail SolutionError, "No Solution Found"
      end
    end
  end

  # Define the groups of cells for this puzzle.  Override this method
  # if you wish to create board that support non-standard cell
  # groupings (such as http://www.websudoku.com/variation/?day=2)
  def define_groups
    @groups = define_columns +
      define_rows +
      define_blocks
  end

  # Define row groups.
  def define_rows
    define_groupings(
      "aaaaaaaaa" +
      "bbbbbbbbb" +
      "ccccccccc" +
      "ddddddddd" +
      "eeeeeeeee" +
      "fffffffff" +
      "ggggggggg" +
      "hhhhhhhhh" +
      "iiiiiiiii")
  end

  # Define column groups.
  def define_columns
    define_groupings(
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi" +
      "abcdefghi")
  end

  # Define block groups.
  def define_blocks
    define_groupings(
      "aaabbbccc" +
      "aaabbbccc" +
      "aaabbbccc" +
      "dddeeefff" +
      "dddeeefff" +
      "dddeeefff" +
      "ggghhhiii" +
      "ggghhhiii" +
      "ggghhhiii")
  end

  # Define a set of groups as specified by a 9x9 string stored in
  # row-major format.  Each position in the string represents a cell
  # on the grid.  Each character value in the string represents a
  # grouping of cells.  All cell positions with the same character
  # will be put in the same group.
  def define_groupings(string)
    groups = Hash.new { |h, k| h[k] = Group.new }
    group_ids = string.split(//)
    cells.each do |cell|
      group_id = group_ids.shift
      next unless group_id =~ /^[a-zA-Z]$/
      groups[group_id] << cell
    end
    groups.values
  end

  def say(message)
    puts message if @verbose
  end
  public :say
end

# Base class for solution strategies.
#
# Provides:
# * Access to board
# * verbose controlled output
# * Cell assignment (with statistics)
#
class SolutionStrategy
  def initialize(board)
    @board = board
    @assignments = 0
  end

  def statistics
    { assignments: @assignments }
  end

  private

  def say(*args)
    @board.say(*args)
  end

  def board
    @board
  end

  def assign(cell, number, msg)
    say "Put #{number} at #{cell} (#{msg})"
    cell.number = number
    @assignments += 1
  end
end

# If any cell has only one possible number that may be assigned to it,
# then assign that number.
#
class CellStrategy < SolutionStrategy
  # Find a cell with only one possibility and fill it.  Return true if
  # you are able to fill a square, otherwise return false.
  def solve
    board.cells.each do |cell|
      an = cell.available_numbers
      if an.size == 1
        assign(cell, an.to_a.first, "Cell")
        return true
      end
    end
    return false
  end
end

# If within any group there is a number that can only be assigned to
# single cell, then assign that number to the cell.
#
class GroupStrategy < SolutionStrategy
  # Find a number that has only one possible assignment in a given
  # group.
  def solve
    board.groups.each do |group|
      group.open_cells_map.each do |number, cells|
        if cells.size == 1
          assign cells.first, number, "Group"
          return true
        end
      end
    end
    return false
  end
end

# Guess a cell assignment.
#
# If the board is not stuck, then make a guess at an arbitrary cell.
# Remember the cell and the other choices. Choose the arbitrary cell
# by looking for cells with the fewest number of choices (this
# minimizes backtracking).
#
# If the board is stuck, then restore the board to a previous state
# and make a different choice.
#
# If the board is stuck, and there are no alternatives, then we can't
# move.
#
class BacktrackingStrategy < SolutionStrategy
  def initialize(board)
    super
    @alternatives = []
    @backtrack = 0
    @max_alternatives = 0
  end

  def statistics
    super.merge(backtrack: @backtrack, max_alternatives: @max_alternatives)
  end

  def solve
    if ! board.stuck?
      cell = find_candidate_for_guessing
      remember_alternatives(cell)
      guess
    elsif @alternatives.empty?
      false
    else
      say "Backtracking (#{plural(@alternatives.size, 'alternative')} available)"
      @backtrack += 1
      guess
    end
  end

  private

  # Find a candidate cell for guessing.  The candidate must be an
  # unassigned cell.  Prefer cells with the fewest number of available
  # numbers (just to minimize backtracking).
  def find_candidate_for_guessing
    unassigned_cells.sort_by { |cell|
      [cell.available_numbers.size, to_s]
    }.first
  end

  # Return a list of unassigned cells on the board.
  def unassigned_cells
    board.cells.to_a.reject { |cell| cell.number }
  end

  # Remember the all the alternative choices for the given cell on the
  # list of alternatives.  An alternative is stored as a 3-tuple
  # consisting of the current encoded state of the board, the cell and
  # an available number.
  def remember_alternatives(cell)
    cell.available_numbers.each do |n|
      @alternatives.push([board.encoding, cell, n])
    end
    @max_alternatives = [@max_alternatives, @alternatives.size].max
  end

  # Make a guess by pulling an alternative from the list of remembered
  # alternatives and.  The state of the board at the remembered
  # alternative is restored and the choice is made for that cell.
  def guess
    state, cell, number = @alternatives.pop
    board.parse(state)
    assign(cell, number, "Guessing, #{plural(@alternatives.size, 'alternative')} remaining")
    true
  end

  # Pluralize +word+.  Assume simply adding an 's' is sufficient.
  def plural(n, word)
    if n == 1
      "#{n} #{word}"
    else
      "#{n} #{word}s"
    end
  end
end

class SudokuSolver
  attr_reader :verbose, :statistics

  STRATEGIES = {
    'c' => CellStrategy,
    'g' => GroupStrategy,
    'b' => BacktrackingStrategy,
  }

  def initialize
    @verbose = false
    @strategy_chars = 'cgb'
  end

  def new_board(string)
    board = Board.new(@verbose).parse(string)
    board.strategies = strategy_classes.map { |sc| sc.new(board) }
    board
  end

  def solve(string)
    board = new_board(string)
    puts board
    t = Time.now
    begin
      board.solve
      @solution_time = Time.now - t
      @statistics = Hash[board.strategies.map { |s| [s.class, s.statistics] }]
      puts
      puts board
      puts
      show_statistics if @verbose
    rescue Board::SolutionError => ex
      puts ex.message
    end
  end

  def run(args)
    if args.empty?
      puts "Usage: ruby sudoku.rb sud-files..."
      exit
    end
    files = []
    args.each do |arg|
      case arg
      when /^--$/
        # noop
      when /^-v$/
        @verbose = ! @verbose
      when /^-s([cgb]*)$/
        @strategy_chars = $1
      when /^[^-]/
        files << arg
      else
        puts "Unrecognized option '#{arg}'"
        exit 1
      end
    end

    files.each do |fn|
      puts "Solving #{fn} ----------------------------------------------"
      puts
      open(fn) do |f|
        solve(f.read)
      end
    end
  end

  def show_statistics
    total = @statistics.inject(0) { |sum, (strat, hash)| sum + hash[:assignments] }
    puts "Total Assignments: #{total}"
    puts "Solution Time: #{'%4.2f' % @solution_time} seconds"
    @statistics.each do |strat, hash|
      puts "#{strat}"
      hash.each do |key, value|
        puts "    #{key}: #{value}"
      end
    end
  end

  def strategy_classes
    @strategy_chars.chars.map { |c| STRATEGIES[c] }
  end

end

SudokuSolver.new.run(ARGV) if __FILE__ == $0
