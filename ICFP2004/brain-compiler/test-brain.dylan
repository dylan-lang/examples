module: assemblerdefine brain test-brain1  start: Move => problem;         Flip 10 (turn-left, turn-right);  turn-right:         Turn Right;         Move start  => problem;  turn-left:         Turn Left;         Move start  => problem; end;