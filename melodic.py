from github_webhook import Webhook
from flask import Flask
from synthplayer.playback import Output
from synthplayer.streaming import AudiofileToWavStream, SampleStream, StreamingSample
from synthplayer.sample import Sample
import random
import sys

app = Flask(__name__)  # Standard Flask app
webhook = Webhook(app) # Defines '/postreceive' endpoint

audio_out = Output(mixing='mix', queue_size=3)

windchimes = [
    'samples/n_C4.mp3',
    'samples/n_C5.mp3',
    'samples/n_D4.mp3',
    'samples/n_D5.mp3',
    'samples/n_E5.mp3',
    'samples/n_F4.mp3',
    'samples/n_G4.mp3'
]

@app.route("/")        # Standard Flask endpoint
def hello_world():
    return "Hello, World!"

@webhook.hook()        # Defines a handler for the 'push' event
def on_push(data):
    print("Got push webhook call")
    try:
        play_sound()
    except:
        e = sys.exc_info()[0]
        print(str(e))
        pass
    #print("Got push with: {0}".format(data))

def play_sound():
    with AudiofileToWavStream(random.choice(windchimes)) as wavstream:
        sample = StreamingSample(wavstream, wavstream.name)
        audio_out.play_sample(sample)

from pynput import mouse

def on_move(x, y):
    pass
    #print('Pointer moved to {0}'.format(
    #    (x, y)))

def on_click(x, y, button, pressed):
    print('{0} at {1}'.format(
        'Pressed' if pressed else 'Released',
        (x, y)))
    if pressed:
        try:
            play_sound()
        except:
            e = sys.exc_info()[0]
            print(str(e))
            pass
    #if not pressed:
        # Stop listener
        #return False

def on_scroll(x, y, dx, dy):
    pass
    #print('Scrolled {0} at {1}'.format(
    #    'down' if dy < 0 else 'up',
    #    (x, y)))

if __name__ == "__main__":
    # ...or, in a non-blocking fashion:
    # listener = mouse.Listener(
    #     on_move=on_move,
    #     on_click=on_click,
    #     on_scroll=on_scroll)
    # listener.start()

    app.run(host="0.0.0.0", port=3500)