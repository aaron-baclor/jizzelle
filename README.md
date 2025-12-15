# jizzelle
21 2048 67
## LAYERS
- Layer 1 — Input layer
“What key did the user press?”
- Layer 2 — Game rules
“What should happen when that key is pressed?”
- Layer 3 — Board mutation
“Which numbers move where in memory?”

## Layer 1: Input Handling and Command Dispatch
The input handling layer is responsible for reading keyboard input from the user and routing the program to the appropriate handler routine based on the pressed key. This layer does not implement any tile movement or merging logic; it only determines which game action should be triggered.
### Keyboard Input
The program reads a single character from standard input using the RISC-V ```ecall``` with service number 63. The character is stored in a one-byte buffer (```inbuf```) and loaded into a temporary register for comparison.
### Key Constants
ASCII values for valid game commands are defined using assembler constants:
- ```W``` (119): swipe up
- ```A``` (97): swipe left
- ```S``` (115): swipe down
- ```D``` (100): swipe right
- ```X``` (120): exit the game
Defining these constants improves readability and avoids the use of hard-coded magic numbers.
### Input Routing (Dispatcher)
After reading a character, the program compares it against the valid command keys using a sequence of ```beq``` instructions. Each comparison conditionally jumps to a corresponding handler label:
- ```handle_w```
- ```handle_a```
- ```handle_s```
- ```handle_d```
- ```handle_exit```
If the input does not match any valid command, control returns to the main input loop and waits for another keypress.

### Direction Handlers
Each direction key has a dedicated handler label. At this stage:
- ```handle_w```,```handle_a```, ```handle_s```, and ```handle_d``` are implemented as stubs that immediately return to the main loop.

These stubs serve as extension points where movement and merging logic will be implemented in later layers.

### Exit Handling
When the user presses ```X```, the program terminates immediately using the RISC-V exit system call (```ecall 10```), as required by the project specification.

### Design Rationale
Separating input handling from movement logic ensures that:
- Keyboard interpretation is centralized and consistent.
- Each direction can later be implemented independently without duplicating input code.
- The program structure remains modular and easier to debug in assembly.
This completes Layer 1, providing a stable foundation for implementing tile movement and merging in subsequent layers.

---

## Layer 2: Game Rules and Move Resolution

**What should happen when that key is pressed?**

The game rules layer defines the logical consequences of a valid swipe input on the current board state. This layer does not perform memory writes or index arithmetic. It specifies how tiles are allowed to move, merge, and trigger game-state changes.

This layer is executed only after a valid direction key (`W`, `A`, `S`, `D`) is identified.

---

## Scope

This layer determines:

* How tiles are interpreted for a given direction
* When tiles move
* When tiles merge
* When a move is valid
* When a new tile is spawned
* When win or loss conditions are triggered

This layer does not modify memory, print output, or read input.

---

## Direction Semantics (3×3 Grid)

* **Swipe Left (`A`)**

  * Process each row independently
  * Tiles move toward column 0
  * Traversal order: left to right

* **Swipe Right (`D`)**

  * Process each row independently
  * Tiles move toward column 2
  * Traversal order: right to left

* **Swipe Up (`W`)**

  * Process each column independently
  * Tiles move toward row 0
  * Traversal order: top to bottom

* **Swipe Down (`S`)**

  * Process each column independently
  * Tiles move toward row 2
  * Traversal order: bottom to top

Traversal order determines blocking and merge priority.

---

## Tile Movement Rules

* Tiles slide in the swipe direction
* A tile stops when it reaches the edge of the grid or is blocked by another tile
* Empty cells do not block movement
* A tile may move if a blocking tile moves first

---

## Tile Merging Rules

* Two tiles merge only if they collide due to a swipe and have the same value
* The merged tile’s value is the sum of the two tiles
* Only one merge per tile is allowed per move

Examples:

```
[2, 2, 0] → [4, 0, 0]
[8, 0, 8] → [16, 0, 0]
```

---

## Merge Constraints

* A tile may merge at most once per move
* Merges are processed in traversal order
* Newly created tiles cannot merge again in the same move

---

## Post-Merge Sliding

* After merges, empty gaps may appear
* A final slide in the same direction is applied
* No further merges occur during this slide

---

## Move Validity

A move is valid if:

* At least one tile moves, or
* At least one merge occurs

If neither happens:

* The move is ignored
* No new tile is added

---

## New Tile Generation

After a valid move:

* A new tile with value `2` is added
* It is placed in the first empty cell when scanning top to bottom, left to right

---

## Win Condition

* If any tile reaches value `512`, the game is won
* The program prints the win message and terminates immediately

---

## Loss Condition

* If the grid has no empty cells and no possible merges, the game is lost
* The program prints the game over message and terminates

---

## Interface with Layer 3

This layer provides:

* Direction
* Traversal order
* Merge eligibility
* Flags for movement, merging, spawning, and termination

Layer 3 performs index calculations and memory updates.

---
