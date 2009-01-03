#!/usr/bin/env ruby

require 'sudoku'

class SqiggleBoard < Board
  def define_blocks
    define_groupings(
      "aaaabbbcc" +
      "aaabbbccc" +
      "aabbbcccd" +
      "eeffffcdd" +
      "eeeefdddd" +
      "eegffffdd" +
      "eggghhhii" +
      "ggghhhiii" +
      "gghhhiiii")
  end
end

class SquiggleSolver < SudokuSolver
  def new_board(string)
    SqiggleBoard.new(true).parse(string)
  end
end


if __FILE__ == $0 then
  SquiggleSolver.new.run(ARGV)
end
