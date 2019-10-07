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

piano_samples = [
    'samples/piano_C4.mp3',
    'samples/piano_C5.mp3',
    'samples/piano_D5.mp3',
    'samples/piano_E5.mp3',
    'samples/piano_G4.mp3'
]

@app.route("/")        # Standard Flask endpoint
def hello_world():
    return "Hello, World!"

@webhook.hook(event_type='push')        # Defines a handler for the 'push' event
def on_push(data):
    print("Got push webhook call")
    play_windchime()
    #print("Got push with: {0}".format(data))

@webhook.hook(event_type='commit_comment')
def on_commit_comment(data):
    print("Got commit comment")
    play_piano()

@webhook.hook(event_type='pull_request_review_comment')
def on_pull_request_review_comment(data):
    print("Got PR review comment")
    play_piano()


def play_windchime():
    play_sound(windchimes)

def play_piano():
    play_sound(piano_samples)

def play_sound(sample_list):
    try:
        with AudiofileToWavStream(random.choice(sample_list)) as wavstream:
            sample = StreamingSample(wavstream, wavstream.name)
            audio_out.play_sample(sample)
    except:
        e = sys.exc_info()[0]
        print(str(e))
        pass

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
            play_windchime()
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