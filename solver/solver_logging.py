"""Sudoku solver.
Inspired by Richard Bird's solution in Pearls of Functional Algorithm Design.
A board is represented as a matrix of sets: {1-9} means all values are possible
for a given cell; {1} means choices have been narrowed down to a single value, 
ie the cell is filled. An emtpy board has 9^3 possible values; a complete board 
has 9^2 singleton sets.

Logging: emit log of type Model = List (Step Action Transform Stack Board)
as JSON {"model": [[Step], [Step] ...]
"""

from collections import defaultdict
import json

# Board

def group(items, n):
    """Group sequence into n-tuples."""
    return list(zip(*[items[i::n] for i in range(n)]))

def parse(board_str):
    """Parse puzzle input string into board object."""
    assert len(board_str) == 81
    digits = {1, 2, 3, 4, 5, 6, 7, 8, 9}
    board = group(board_str, 9)
    return [[digits if n in ('0', '.') else set([int(n)]) for n in row]
            for row in board]
def to_str(sets):
    """Convert sequence of integer sets to string."""
    return ' '.join(['.' if len(s) > 1 else str(tuple(s)[0])
                     for s in sets])
    
def show(board):
    """Convert board object to string representation."""
    bars = '-' * 21 + '\n'
    output = ''
    row_group = group(board, 3)
    for rows in row_group:
        for row in rows:
            output += ' | '.join([to_str(cols) for cols in group(row, 3)])
            output += '\n'
        output += bars
    return output[:-22]

# Validation

def rows(board):
    """Return board."""
    return board

def cols(board):
    """Return transposed board."""
    return list(zip(*board))

def flatten(nested):
    """Flatten nested sequence of sequences."""
    return list(n for sublist in nested for n in sublist)

def boxs(board):
    """Group board by its boxes.
    For each triple of rows, group each row into 3 digits and 
    zip up the rows; the resulting lists are the board boxes.
    """
    boxes = []
    for grouped in group(board, 3):
        triple = [group(row, 3) for row in grouped]
        zipped = list(zip(*triple))
        rows = [flatten(row) for row in zipped]
        boxes.extend(rows)
    return boxes

def singletons(row):
    """Return all singleton values from list of sets."""
    return [tuple(ns)[0] for ns in row if len(ns) == 1]

def singleton_nums(row):
    """Return all singleton nums from list of sets, excluding singleton sets."""
    exclude = singletons(row)
    ns = [n for nums in row for n in nums 
          if len(nums) > 1 and n not in exclude]
    digits = defaultdict(int)    
    for n in ns:
        digits[n] += 1 
    return [k for k in digits if digits[k] == 1]

def noempties(board):
    """Iterate through board; return True if there are no
    empty cells in any row."""
    return all(ns for ns in flatten(board))

def nodups(board):
    """Iterate through board; return True if there are no 
    duplicate singleton numbers in any row.
    """
    checks = []
    for row in board:
        singles = singletons(row)
        checks.append(len(singles) == len(set(singles)))
    return all(checks)

def valid(board):
    """Return True if board is valid."""
    return (noempties(board) and 
            all(nodups(f(board)) for f in (rows, cols, boxs)))
    
def complete(board):
    """Return True if board is complete."""
    return (valid(board) and 
            all([sum(singletons(row)) == 45 for row in board]))

# Solver

def prune(board):
    """Remove known choices from the board.
    For all non-singleton cells, remove all singleton-cell values
    from the same row.
    """
    rows = []
    for row in board:
        singles = singletons(row)
        new = [ns - set(singles) if len(ns) > 1 else ns
               for ns in row]
        rows.append(new)
    return rows

def fill(board):
    """Fill cells (by removing known choices from the board.
    For all non-singleton cells, if one or more values don't appear
    elsewhere in the row, fill that cell with those values.
    """
    new_board = []
    for row in board:
        singles = singleton_nums(row)
        new_row = []
        for nums in row:
            intersect = set(singles) & set(nums)
            new_nums = intersect if intersect else nums
            new_row.append(new_nums)
        new_board.append(new_row)
    return new_board

def next_boards(board):
    """Generate list of some possible next boards.
    Expand a cell with the minimum number of choices. 
    """
    flat = flatten(board)
    len_choices = [len(ns) for ns in flat if len(ns) > 1]
    
    if not len_choices: return []
    target_len = min(len_choices)

    boards = []
    for ind, ns in enumerate(flat):
        if len(ns) == target_len:
            flats = [flat[:ind] + [set([n])] + flat[ind+1:] for n in ns]
            boards.extend([group(b, 9) for b in flats])
            break
    
    return [b for b in boards if valid(b)]

def score_progress(board):
    """Return # of candidates remaining in board."""
    return sum(sum(len(cell) for cell in row) for row in board)

def add_log(log, step, action, transform, stack, board, step_inc=True):
    """Return updated log and step count."""
    b = [list(cell) for row in board for cell in row]
    log.append([step, action, transform, stack, b])
    return log, step + (1 if step_inc else 0)

def solve(board, log=[]):
    """Solver: prune, fill, and search in order."""
    step = 0
    boards = [board]
    log, step = add_log(log, step, 'Nothing', 'Rows', len(boards), board, False)
    
    while boards:
        board = boards.pop()    
        for t, f in (('Rows', rows), ('Cols', cols), ('Boxes', boxs)):
            board = prune(f(board))
            log, step = add_log(log, step, 'Prune', t, len(boards), board) 
            board = f(fill(board))
            log, step = add_log(log, step, 'Fill', t, len(boards), board)    
            
        if complete(board):
            log, step = add_log(log, step, 'Nothing', 'Rows', len(boards), board, False)
            return show(board)
        
        if valid(board):            
            boards.extend(next_boards(board))
            log, step = add_log(log, step, 'Extend', 'Rows', len(boards), board)
        else:
            log, step = add_log(log, step, 'Invalid', 'Rows', len(boards), board)
            
    log, step = add_log(log, step, 'Nothing', 'Rows', len(boards), board, False)
    return []

def solve_with_log(board, out_fname):
    """Wrapper for solve: write log to out_fname"""
    log = []
    ret = solve(board, log)
    with open(out_fname, 'w') as f:
        f.write(json.dumps({'model': log}, indent=4))
        
    return ret

# Main

def main():
    """Main: run solve() with some samples."""
    with open('samples.txt', 'r') as f:
        puzzles = [parse(line.strip()) for line in f.readlines()]
    for i, p in enumerate(puzzles):
        print('\nSolving puzzle {}'.format(i))
        print(show(p))
        print(solve(p))
    
if __name__ == '__main__':
    main()

    
