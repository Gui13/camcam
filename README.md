# Camcam

This repository contains 2 things:

- a script that you can deploy on your Raspberry Pi equipped with a camera and a PanTiltHat from Pimoroni. Is is located in `/server`

- an XCode project that compiles for iOS and controls both servos from iOS.

The iOS project has a hardwired address on which the device will seek the MJPG stream and call APIs to pan and tilt.

# Installation

### On the raspberry

- install the flask and pimoroni packages

```bash
sudo apt-get install pimoroni
sudo pip install flask
```

- transfer the `camcam.py` file to your raspberry

- issue this command in the console:

```bash
python camcam.py
```

### On iOS

- Modify the `Camcam/ViewController.swift` file and put the raspberry pi IP in the `let pi_url = ""` line.
- Compile and run on your device

