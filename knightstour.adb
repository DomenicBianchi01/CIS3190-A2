--Domenic Bianchi
--CIS 3190
--March 3, 2017
--This is a program that simulates the Knights Tour. This program is based off of the Python program linked in the assignment specification (http://blog.justsophie.com/algorithm-for-knights-tour-in-python/)

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure knightstour is
    type standardArray is array (1..100) of integer;
    type board is array (natural range <>, natural range <>) of integer;
    size, posX, posY : integer;
    tourBoard : board(1..10, 1..10);
    tourDone : exception;
    outfp : file_type;

    --This procedure determines all valid moves from the current location of the knight. Two arrays are returned (x cordinates and y cordinates) containing the valid moves.
    procedure getMoves(posX : in integer; posY : in integer; arrayX: in out standardArray; arrayY: in out standardArray; counter : in out integer) is
    moveOffsetX : array (1..8) of integer;
    moveOffsetY : array (1..8) of integer;
    newX, newY : integer;
    begin
        counter := 1;
        moveOffsetX := (1,1,-1,-1,2,2,-2,-2);
        moveOffsetY := (2,-2,2,-2,1,-1,1,-1);
	
	--There is a maximum of eight moves
        for i in 1..8 loop
            newX := posX + moveOffsetX(i);
            newY := posY + moveOffsetY(i);
            --If the possible move exceeds the size of the board or is less than 1 then the move is not valid
            if newX <= size and newY <= size and newX >= 1 and newY >= 1  then
                --Add the cordinates of the valid move to the arrays
                arrayX(counter) := newX;
                arrayY(counter) := newY;
                counter := counter + 1;
            end if;
        end loop;
    counter := counter - 1;
    end getMoves;

    --This procedure determines out of all valid moves, which squares the knight has not yet reached, and out of those, which square is the most efficent to traverse to
    procedure getSortedNeighbours(counter2: in out integer; neighboursX: in out standardArray; neighboursY: in out standardArray; posX : integer; posY : integer) is
    emptyNeighboursX : standardArray;
    emptyNeighboursY : standardArray;
    scoresIndex : standardArray;
    counter, value, score, scoresCounter, tempX, tempY, tempScore : integer;
    begin
        counter := 0;
        counter2 := 1;
        scoresCounter := 1;
        getMoves(posX, posY, emptyNeighboursX, emptyNeighboursY, counter);
        --Given a set of valid moves, determine which squares (from the valid moves) the knight has yet to reach
        for i in 1..counter loop
            value := tourBoard(emptyNeighboursX(i), emptyNeighboursY(i));
            if value = 0 then
                neighboursX(counter2) := emptyNeighboursX(i);
                neighboursY(counter2) := emptyNeighboursY(i);
                counter2 := counter2 + 1; 
            end if;
        end loop;
        counter2 := counter2 - 1;

        --Given each sqaure (per move) that the knight has not yet reached, determine which squares have the least amount of moves to reach them. Going to the squares that have the least amount of moves leading to them is the more efficent to go to early as it may become harder to reach later 
        for i in 1..counter2 loop
            score := 0;
            getMoves(neighboursX(i), neighboursY(i), emptyNeighboursX, emptyNeighboursY, counter);
            for j in 1..counter loop
                if tourBoard(emptyNeighboursX(j), emptyNeighboursY(j)) = 0 then
                    score := score + 1;
                end if;
            end loop;
            scoresIndex(scoresCounter) := score;
            scoresCounter := scoresCounter + 1;
        end loop;
        scoresCounter := scoresCounter - 1;

        --Sort the priority of the squares from least to greatest. The lower the "score" the greater the priority.
        for i in 1..counter2 loop
           for j in 1..counter2 loop
               if scoresIndex(i) < scoresIndex(j) then
                   tempX := neighboursX(i);
                   tempY := neighboursY(i);
                   neighboursX(i) := neighboursX(j);
                   neighboursY(i) := neighboursY(j);
                   neighboursX(j) := tempX;
                   neighboursY(j) := tempY;
                   tempScore := scoresIndex(i);
                   scoresIndex(i) := scoresIndex(j);
                   scoresIndex(j) := tempScore;
                end if;
            end loop;
        end loop;
    end getSortedNeighbours;

    --This procedure prints out the completed board to the terminal at the end of the program and only if a solution is found
    procedure printBoard(size: integer; tourBoard: board) is
    outfp : file_type;
    begin
        --Open/create a text file to save the output of the board
        create(outfp, out_file, "tour.txt");
        for i in 1..size loop
            for j in 1..size loop
                put(tourBoard(i,j));
                put(outfp, tourBoard(i,j));
            end loop;
            new_line;
            put_line(outfp, "");
        end loop;

        --Close text file
        if is_open(outfp) then
            close(outfp);
        end if;

    end printBoard;

    --This procedure is the main recursive function. Assigns the move number to each square as the knight moves around the board and recursivly uses this procedure to find a valid route (if a route proves to be invalid, the program will undo itself and try another route)
    procedure tour (tourBoard: in out board; num: integer; size: integer; posX: integer; posY: integer) is 
    neighboursX : standardArray;
    neighboursY : standardArray;
    neighboursLen : integer;
    begin
        neighboursLen := 1;
        --Update the value of the square with the move number
        if tourBoard(posX, posY) = 0 then
            tourBoard(posX, posY) := num;
        end if;

        --Once the last square has been filled in with a number, all sqaures have been reached and the progam can end.
        if num = size*size then
            printBoard(size, tourBoard);          
            raise tourDone with "Solution Found";
        else
            --Get valid moves from the current position of the knight
            getSortedNeighbours(neighboursLen, neighboursX, neighboursY, posX, posY);
            --Loop through all valid moves
            for i in 1..neighboursLen loop
                tour(tourBoard, num+1, size, neighboursX(i), neighboursY(i)); 
            end loop;

            --If the program reaches this section it means a route was invalid and needs to be undone
            tourBoard(posX, posY) := 0;
        end if;
    end tour;

begin
    --Prompt user for size of board and starting position. Most of the code in this section is used for error checking (invalid inputs by the user)
    --Keep looping until an integer is entered for the board size
    loop
        begin
            put("Enter size of the board: ");
            get(size);
  
            --Board size must be between 5 and 10. In the event that a number outside of this range is entered reprompt (there is no need to raise an exception for this type of error)
            while size > 10 or size < 5 loop
                put("Board size can only be between 5 and 10. Try again: ");
                get(size);
            end loop;

            --Keep looping until an integer is entered for the starting point
            loop
                begin
                    put("Enter starting position (x y): ");
                    get(posX);
                    get(posY);

                    --The top left corner of the board is considered (1,1). Make sure the start point is no less than (1,1) and no more than (size of board, size of board)
                    while posX > size or posY > size or posX < 1 or posY < 1 loop
                        put("Starting position must be within the bounds of the board size. Try again: ");
                        get(posX);
                        get(posY);
                    end loop;

                    --Set all squares on the board to 0
                    for i in 1..size loop
                        for j in 1..size loop
                            tourBoard(i,j) := 0;
                        end loop;
                    end loop;

                    --Start tour
                    tour(tourBoard, 1, size, posX, posY);

                    --Open/create a text file to save the output of the board
                    create(outfp, out_file, "tour.txt");
                    put(outfp, "No Solution");

                    --Close text file
                    if is_open(outfp) then
                        close(outfp);
                    end if;

                    put_line("No Solution");
                    return;
                exception
                    when data_error =>
                        skip_line;
                        put_line("Invalid input. Please make sure you only enter a valid integer");
                end;
            end loop;
        exception
            when data_error =>
                skip_line;
                put_line("Invalid input. Please make sure you only enter a valid integer");
        end;
    end loop;
end knightstour;
