# jizzelle
21 2048 67

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
- Only handle_w performs an action (existing placeholder logic for testing).
- ```handle_a```, ```handle_s```, and ```handle_d``` are implemented as stubs that immediately return to the main loop.

These stubs serve as extension points where movement and merging logic will be implemented in later layers.

### Exit Handling
When the user presses ```X```, the program terminates immediately using the RISC-V exit system call (```ecall 10```), as required by the project specification.

### Design Rationale
Separating input handling from movement logic ensures that:
- Keyboard interpretation is centralized and consistent.
- Each direction can later be implemented independently without duplicating input code.
- The program structure remains modular and easier to debug in assembly.
This completes Layer 1, providing a stable foundation for implementing tile movement and merging in subsequent layers.

### ✔️ What your pairmate can safely do next
They can now:
- implement movement logic inside ```handle_w / handle_a / handle_s / handle_d```
- trust that input routing already works
- avoid touching main_loop

Next logical layer (for whoever does it):
👉 Implement “slide without merge” for one direction

When you’re ready, I’ll walk you through that using index math, not guesswork.
