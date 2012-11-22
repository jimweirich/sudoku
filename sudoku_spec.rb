require 'rspec/given'
require 'sudoku'

describe Cell do

  def create_group_with(cell, *numbers)
    g = Group.new
    g << cell
    numbers.each do |n|
      c = Cell.new
      c.number = n
      g << c
    end
    g
  end

  describe 'a cell' do
    Given(:cell) { Cell.new("C25") }

    Then { cell.to_s.should == "C25" }
    Then { cell.inspect.should ==  "C25" }
    Then { cell.number.should be_nil }
    Then { cell.available_numbers.should == Set[*(1..9)] }

    context 'when setting the number' do
      When { cell.number = 4 }
      Then { cell.number.should == 4 }
    end

    context 'when setting number to zero' do
      When { cell.number = 0 }
      Then { cell.number.should be_nil }
    end

    context 'within a group' do
      Given!(:group) { create_group_with(cell, 3, 4, 5) }
      Then { cell.available_numbers.should == Set[1, 2, 6, 7, 8, 9] }

      context "when assigning a number" do
        When { cell.number = 6 }
        Then { cell.available_numbers.should == Set[] }
      end
    end
  end
end

describe Group do
  Given(:group) { Group.new }

  Then { group.should_not be_nil }

  context 'with cells' do
    Given(:cells) { (1..10).map { |i| Cell.new("C#{i}") } }
    Given { cells.each do |c| group << c end }

    Then { group.numbers.should == Set[] }

    context 'with some numbers' do
      Given {
        cells[0].number = 3
        cells[3].number = 6
      }
      Then { group.numbers.sort.should == [3, 6] }
    end
  end
end

module Puzzles
  Wiki =
    "53  7    " +
    "6  195   " +
    " 98    6 " +
    "8   6   3" +
    "4  8 3  1" +
    "7   2   6" +
    " 6    28 " +
    "   419  5" +
    "    8  79"

  Medium =
    " 4   7 3 " +
    "  85  1  " +
    " 15 3  9 " +
    "5   7 21 " +
    "  6   8  " +
    " 81 6   9" +
    " 2  4 57 " +
    "  7  29  " +
    " 5 7   8 "

  Evil =
    "  53 694 " +
    " 3 1    6" +
    "       3 " +
    "7  9     " +
    " 1  3  2 " +
    "     2  7" +
    " 6       " +
    "8    7 5 " +
    " 436 81  "
end

describe Board do

  Given(:board) { Board.new }

  Then { board.inspect.should =~ %r(^<Board \.{81}>$) }

  Then {
    board.each do |cell|
      cell.available_numbers.sort.should == (1..9).to_a
    end
  }

  describe 'parse a string representation of the puzzle' do
    Given { board.parse(Puzzles::Wiki) }
    Then {
      board.to_s.should == (
        "5 3 .  . 7 .  . . .  \n" +
        "6 . .  1 9 5  . . .  \n" +
        ". 9 8  . . .  . 6 .  \n\n" +
        "8 . .  . 6 .  . . 3  \n" +
        "4 . .  8 . 3  . . 1  \n" +
        "7 . .  . 2 .  . . 6  \n\n" +
        ". 6 .  . . .  2 8 .  \n" +
        ". . .  4 1 9  . . 5  \n" +
        ". . .  . 8 .  . 7 9  \n\n")
    }

    describe 'solve the Wikipedia Puzzle' do
      When { board.solve }

      Then { board.should be_solved }
      Then { board.encoding.should ==
        "534678912672195348198342567" +
        "859761423426853791713924856" +
        "961537284287419635345286179"
      }
    end
  end

  describe 'solve the Wikipedia Puzzle with DOS line endings' do
    Given(:board) { Board.new.parse(open("puzzles/wiki_dos.sud") { |f| f.read }) }
    When { board.solve }

    Then { board.should be_solved }
    Then { board.encoding.should ==
      "534678912672195348198342567" +
      "859761423426853791713924856" +
      "961537284287419635345286179"
    }
  end

  describe 'solve the Medium Puzzle' do
    Given(:board) { Board.new.parse(Puzzles::Medium) }
    When { board.solve }
    Then { board.should be_solved }
    Then { board.encoding.should ==
      "942187635368594127715236498" +
      "593478216476921853281365749" +
      "829643571137852964654719382"
    }
  end

  describe 'solve the Evil Puzzle' do
    Given(:board) { Board.new.parse(Puzzles::Evil) }
    When { board.solve }

    Then { board.should be_solved }
    Then { board.encoding.should ==
      "285376941439125786176849235" +
      "752981364618734529394562817" +
      "567213498821497653943658172"
    }
  end
end

describe "Sudoku Solver" do
  WikiPuzzleFile = 'puzzles/wiki.sud'
  SOLUTION = %{5 3 4  6 7 8  9 1 2
6 7 2  1 9 5  3 4 8
1 9 8  3 4 2  5 6 7

8 5 9  7 6 1  4 2 3
4 2 6  8 5 3  7 9 1
7 1 3  9 2 4  8 5 6

9 6 1  5 3 7  2 8 4
2 8 7  4 1 9  6 3 5
3 4 5  2 8 6  1 7 9}

  SOL_PATTERN = SOLUTION.gsub(/\s+/,'\s+')

  def redirect_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  Given(:solver) { SudokuSolver.new }

  describe 'solve a puzzle' do
    Given(:result) {
      redirect_output do
        solver.run([WikiPuzzleFile])
      end
    }
    Then { result.should =~ /#{SOL_PATTERN}/ }
  end

  describe 'complain if no file given' do
    Given(:result) {
      redirect_output do
        result = nil
        begin
          solver.run([])
        rescue SystemExit => ex
          result = ex
        end
        result
      end
    }
    Then { result.should =~ /Usage:/ }
  end
end
