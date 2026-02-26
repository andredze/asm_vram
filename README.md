# Frame

Program draws an animation of a frame pulsing with text in center of the screen
Supposed to be ran on DOSBox

# Build program
```powershell
    tasm /la vram.asm
    tlink /t vram.obj
```

# Run program

## Format
```powershell
    vram.com <FrameStyle> <FrameWidth> <FrameHeight> <YourText>
```

## Frame styles
```text
0 - normal frame with gray bg
1 - pink hearts
2 - red strange symbols
3 - blue stupid symbols
4 - funny yellow faces on red bg
```

## Example
Draw a frame with pink hearts, size=30*7 with text "Privet, Mir!"
```powershell
    vram.com 1 30 7 Privet, Mir!
```
