#[
 _   _ _               _ _      
| \ | (_)_ __ ___   __| | | ___ 
|  \| | | '_ ` _ \ / _` | |/ _ \
| |\  | | | | | | | (_| | |  __/
|_| \_|_|_| |_| |_|\__,_|_|\___|

its wordle but in nim

]#

import std/terminal
import std/random
import std/tables
import std/strutils

# Randomize seed
randomize()

const
  MAX_TRIES: int = 6
  KEYMAP_PADDING: int = 4
  # Words the player can use to guess
  wordlist = staticRead("wordlist.txt").split('\n')
  # Words to pick for the secret
  words = staticRead("words.txt").split('\n')

let
  # Secret word
  secret = sample(words)
  # Keyboard map
  keymaps = {
    "QWERTY": ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
  }.toTable()
  keymap = keymaps["QWERTY"]

# https://stackoverflow.com/a/32104275
proc toString(str: seq[char]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    add(result, ch)

proc moveCursorY(count: int) = 
  if count > 0:
    cursorDown(count)
  elif count < 0:
    cursorUp(-count)

var
  # User input
  guess: string
  buffer: seq[char]
  key: char
  code: int
  # Remaining moves
  moves: int = MAX_TRIES
  # Used for highlighting
  build: string
  keymap_x: int
  keymap_y: int
  # 0 - not tried
  # 1 - not in word
  # 2 - in word but wrong position
  # 3 - in word and correct position
  alphabet = {'A': 0,'B': 0,'C': 0,'D': 0,'E': 0,'F': 0,'G': 0,'H': 0,'I': 0,'J': 0,'K': 0,'L': 0,'M': 0,'N': 0,'O': 0,'P': 0,'Q': 0,'R': 0,'S': 0,'T': 0,'U': 0,'V': 0,'W': 0,'X': 0,'Y': 0,'Z': 0}.toTable()

# Draw the board
echo(repeat("▯▯▯▯▯\n", MAX_TRIES))
cursorUp(MAX_TRIES + 1)

cursorForward(5 + KEYMAP_PADDING)
for line in keymap:
  stdout.write(line)
  cursorDown(1)
  cursorBackward(len(line))

cursorUp(3)
setCursorXPos(0)

while true:
  # Read input
  while true:
    key = getch()
    code = ord(key)

    # Backspace
    if code == 127:
      if len(buffer) > 0:
        cursorBackward(1)
        stdout.write("▯")
        cursorBackward(1)
        discard buffer.pop()

    # Enter
    elif code == 13:
      if len(buffer) == 5:
        guess = toUpperAscii(toString(buffer))
        buffer.setLen(0)
        break

    # Interrupt codes CTRL+(C, D, Z)
    elif code in [3, 4, 26]:
      cursorDown(moves)
      quit(0)

    # Other keys /[a-zA-Z]/
    elif len(buffer) < 5 and ((97 <= code and code <= 122) or (65 <= code and code <= 90)):
      stdout.write(toUpperAscii(key))
      buffer.add(key)

  setCursorXPos(0)

  # Clear line if guess isn't valid
  if guess notin wordlist:
    stdout.write("▯▯▯▯▯")
    setCursorXPos(0)
    continue

  moves -= 1

  # Highlight the letters
  for i, c in guess:
    for y, k in keymap:
      if c in k:
        keymap_y = y
        break
    keymap_x = keymap[keymap_y].find(c)

    if secret[i] == c:
      stdout.setBackGroundColor(bgGreen, true)
      if alphabet[c] < 3:
        alphabet[c] = 3
    else:
      if build.count(c) < secret.count(c):
        stdout.setBackGroundColor(bgYellow, true)
      else:
        stdout.setBackGroundColor(bgBlack, true)

      if c in secret and alphabet[c] < 2:
        alphabet[c] = 2
      else:
        alphabet[c] = 1
      
      build.add(c)

    stdout.write(c)

    setCursorXPos(5 + KEYMAP_PADDING + keymap_x)
    moveCursorY(-(MAX_TRIES - moves - 1) + keymap_y)
    stdout.write(c)
    setCursorXPos(i + 1)
    moveCursorY((MAX_TRIES - moves - 1) - keymap_y)

    stdout.resetAttributes()

  # Reset build variable
  build = ""

  # Move cursor down
  cursorDown(1)
  setCursorXPos(0)

  # Exit game if the guess is correct
  if guess == secret:
    cursorDown(moves + 1)
    echo("You win!")
    break

  # Exi game if moves are depleted
  if moves == 0:
    cursorDown(moves)
    echo("You lost!\nThe word was: ", secret)
    break
