import solver

with open('samples_many.txt', 'r') as f:
    lines = [line.strip() for line in f.readlines()[:5]]
    PUZZLES = [solver.parse(p) for p in lines]

class TestSolver:
    """Unit tests for sudoku solver."""
    
    def test_transforms(self):
        """Test rows cols boxs transofmrations."""
        r = solver.rows
        c = solver.cols
        b = solver.boxs
        p = PUZZLES[0]
        assert p == b(b(c(c(r(r(p))))))

    def test_singletons(self):
        """Test singletons."""
        assert solver.singletons([{1}, {1,2}, {}]) == [1]
        assert solver.singletons([{1}, {1,2}, {3}, {4,5,6}]) == [1,3]

    def test_singleton_nums(self):
        """Test singleton_nums."""
        f = solver.singleton_nums
        assert f([{2,3}, {4}]) == [2, 3]
        assert (f([{1}, {2}, {3,4,5}, {3}, {5,6,7}, {5,7,9}]) == [4, 6, 9])

    def test_verify(self):
        """Verify some validation and sample board properties."""
        board = PUZZLES[2]
        assert solver.valid(board) is True
        assert solver.complete(board) is False
        assert len(board) == 9

    def test_noempties(self):
        """Test noempties"""
        assert solver.noempties([[{1,2,3},{1}], [{0}]]) is True
        assert solver.noempties([[{1,2,3},{}], [{0}]]) is False        

    def test_nodups(self):
        """Test nodups"""
        assert solver.nodups([[{1}, {1}], [{2}]]) is False
        assert solver.nodups([[{2}, {1}], [{2}]]) is True

    def test_prune(self):
        """Test prune."""
        b = [[{1}, {1,2,3}, {2}, {3,4}]]
        assert solver.prune(b) == [[{1}, {3}, {2}, {3,4}]]

        b2 = [[{1}, {1,2,3}, {2}, {3,4}],
              [{1,2}, {5}, {6}, {7}]]
        b2prime = [[{1}, {1,2,3}, {2}, {3,4}],
                   [{2}, {5}, {6}, {7}]]
        assert (solver.prune(solver.cols(b2)) ==
                list(list(cell) for cell in solver.cols(b2prime)))

    def test_fill(self):
        """Test fill."""
        b = [[{1}, {2,3}, {3,4,5}, {7}]]
        bPrime = [[{1}, {2}, {4,5}, {7}]]
        assert solver.fill(b) == bPrime
