# SEKVENCE Feature - User Guide

## Overview
The SEKVENCE feature allows you to execute pre-programmed motion sequences on your robot arm. You can use built-in default sequences or create your own custom sequence files.

## Accessing SEKVENCE
1. Connect to your robot via Bluetooth
2. Navigate to the Servo Control screen
3. Scroll down and tap the **SEKVENCE** button

## Using Default Sequences
1. In the SEKVENCE screen, select from the dropdown:
   - **Default 1**: Basic Wave Motion - demonstrates base rotation and shoulder movement
   - **Default 2**: Grab and Release - simulates picking up and releasing an object
   - **Default 3**: Scanning Motion - performs a scanning pattern with base, shoulder, elbow, and wrist
2. (Optional) Enable the **Loop** checkbox to repeat the sequence continuously
3. Tap **Spustit** to start execution
4. Tap **Stop** to stop at any time

## Creating Custom Sequences
1. Create a `.txt` file on your device with the following format:
   ```
   # Comments start with # or //
   pin,angle,speed,delayMs
   pin,angle,speed          # delayMs defaults to 300ms if not specified
   ```

2. Example sequence file:
   ```
   # My custom sequence
   12,90,50,500    # Move BASE to 90° at speed 50, wait 500ms
   10,45,60,800    # Move SHOULDER to 45° at speed 60, wait 800ms
   8,120,50        # Move ELBOW to 120° at speed 50, wait 300ms (default)
   ```

3. In the SEKVENCE screen:
   - Select **Vlastní soubor…** from the dropdown
   - Tap **Vybrat soubor** to choose your `.txt` file
   - Review the parsed sequence in the status area
   - Tap **Spustit** to execute

## Sequence File Format Details

### Valid Line Format
- `pin,angle,speed,delayMs` - Full format with custom delay
- `pin,angle,speed` - Uses default 300ms delay

### Parameters
- **pin**: Servo pin number (matches your robot configuration)
  - 12 = BASE
  - 10 = SHOULDER
  - 8 = ELBOW
  - 2 = WRIST
  - 0 = HAND
- **angle**: Target angle in degrees (0-180)
- **speed**: Movement speed (1-255, higher = faster)
- **delayMs**: Delay in milliseconds before next command (≥ 0)

### Comments
- Lines starting with `#` or `//` are ignored
- Empty lines are ignored

### Example
```
# Robot wave sequence
// Move base left and right
12,30,60,1000
12,150,60,1000
12,90,60,500

# Shoulder nod
10,40,50,600
10,0,50,600
```

## Loop Mode
When **Loop** is enabled:
1. The sequence executes completely
2. Robot automatically resets to default positions (500ms per servo)
3. Sequence starts again from the beginning
4. Continues until you press **Stop** or leave the SEKVENCE screen

**Note**: Loop automatically disables when you stop execution or navigate away.

## Safety Features
- **Bluetooth Required**: Sequence won't start without active connection
- **Servo Controls Locked**: All manual servo controls are disabled during sequence execution to prevent conflicts
- **Validation**: Sequence files are validated before execution - errors are shown in the status area
- **Clean Stop**: Pressing Stop immediately halts execution and leaves the robot at its current position

## Troubleshooting

### "Sekvence je prázdná nebo neplatná"
- Check that your file contains valid sequence lines (not just comments)
- Verify file format matches the specification

### "Chyba na řádku X: ..."
- Check the error message for details
- Common issues:
  - Invalid number format
  - Angle out of range (must be 0-180)
  - Speed out of range (must be 1-255)
  - Wrong number of values per line

### "Bluetooth není připojeno!"
- Ensure you're connected to your robot before starting a sequence
- Return to the home screen and reconnect if needed

## Tips
- Start with slow speeds (20-40) when testing new sequences
- Use longer delays (500-1000ms) for safety when learning
- Test sequences step-by-step before enabling loop mode
- Keep sequences short initially to verify behavior
- Comment your sequence files for future reference
