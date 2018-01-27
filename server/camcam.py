#!/usr/bin/env python

try:
    import pantilthat
except ImportError:
    exit("This script requires the pantilthat module, which is provided by pimoroni package\nInstall with sudo apt-get install pimoroni")

from sys import exit

try:
    from flask import Flask, render_template, Response
except ImportError:
    exit("This script requires the flask module\nInstall with: sudo pip install flask")

app = Flask(__name__)

@app.route('/')
def home():
    return 'Nope.'

@app.route('/api/<direction>/<int:angle>')
def api(direction, angle):
    if angle < 0 or angle > 180:
        return "{'error':'out of range'}"

    angle -= 90

    if direction == 'pan':
        pantilthat.pan(angle)
        return "{{'pan':{}}}".format(angle)

    elif direction == 'tilt':
        pantilthat.tilt(angle)
        return "{{'tilt':{}}}".format(angle)

    return "{'error':'invalid direction'}"

def generate_image():
    while True:
        image = open('/dev/shm/mjpeg/cam.jpg').read()
        yield (b'--camcam\r\n'
                   b'Content-Type: image/jpeg\r\n'
                   b'Content-Length: ' + str(len(image)) + b'\r\n'
                   b'\r\n' + image + b'\r\n')



@app.route('/livecam')
def livecam():
    response = Response(generate_image(), mimetype='multipart/x-mixed-replace; boundary=camcam')
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Connection'] = 'close'
    return response

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=9595, debug=True, threaded=True)

