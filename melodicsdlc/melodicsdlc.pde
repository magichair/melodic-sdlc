
import processing.sound.*;
import java.util.Random;
import org.rapidoid.setup.On;
import org.rapidoid.http.ReqHandler;
import org.rapidoid.http.Req;
import com.github.kevinsawicki.timeago.TimeAgo;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

import java.util.concurrent.ConcurrentLinkedQueue;

Random rand = new Random(System.currentTimeMillis());
SoundFile[] windchimes;
SoundFile[] pianoSamples;
ConcurrentLinkedQueue<Event> eventQueue = new ConcurrentLinkedQueue();
TimeAgo timeAgo = new TimeAgo();

void setup() {
  size(800, 400);
  //App.bootstrap(new String[]{});
  On.post("/webhook").json(new ReqHandler(){
    public Object execute(Req req){
      Event event = null;
      System.out.println(req.headers());
      if (req.headers().containsKey("x-github-event")) {
        // Github Event
        String eventTypeString = req.headers().get("x-github-event");
        try {
          System.out.println(eventTypeString.toUpperCase());
          event = new Event(EventType.valueOf(eventTypeString.toUpperCase()),
            parseJSONObject(new String(req.body())));
        } catch(Exception e) {
          event = new Event(EventType.OTHER, parseJSONObject(new String(req.body())));
        }
      } else {
        event = new Event(EventType.NON_GITHUB_EVENT, null);
      }
      if (event != null) {
        eventQueue.add(event);
      }
      return "";
    }
  });
  pianoSamples = new SoundFile[]{
    new SoundFile(this, "piano_C4.mp3"),
    new SoundFile(this, "piano_C5.mp3"),
    new SoundFile(this, "piano_D5.mp3"),
    new SoundFile(this, "piano_E5.mp3"),
    new SoundFile(this, "piano_G4.mp3")
  };
  windchimes = new SoundFile[]{
    new SoundFile(this, "n_C4.mp3"),
    new SoundFile(this, "n_C5.mp3"),
    new SoundFile(this, "n_D4.mp3"),
    new SoundFile(this, "n_D5.mp3"),
    new SoundFile(this, "n_E5.mp3"),
    new SoundFile(this, "n_F4.mp3"),
    new SoundFile(this, "n_G4.mp3")
  };
}

class Event {
  EventType eventType;
  JSONObject data;
  
  public Event(EventType eventType, JSONObject data) {
    this.eventType = eventType;
    this.data = data;
  }
  
  public String userAvatar() {
    switch(eventType) {
      case PULL_REQUEST_REVIEW_COMMENT:
      case COMMIT_COMMENT:
      case PUSH:
        return data.getJSONObject("sender").getString("avatar_url");
      default:
        return "";
    }
  }
  
  public String userLogin() {
     switch(eventType) {
      case PULL_REQUEST_REVIEW_COMMENT:
      case COMMIT_COMMENT:
      case PUSH:
        return data.getJSONObject("sender").getString("login");
      default:
        return "";
    }
  }
  
  public String repository() {
     switch(eventType) {
      case PULL_REQUEST_REVIEW_COMMENT:
      case COMMIT_COMMENT:
      case PUSH:
        return data.getJSONObject("repository").getString("name");
      default:
        return "";
    }
  }
  
  public ZonedDateTime timestamp() {
    String timestampString = null; 
    switch(eventType) {
      case PULL_REQUEST_REVIEW_COMMENT:
      case COMMIT_COMMENT:
        timestampString = data.getJSONObject("comment").getString("created_at");
        break;
      case PUSH:
        if (data.getJSONArray("commits").size() > 0) {
          timestampString = data.getJSONArray("commits").getJSONObject(0).getString("timestamp");
        }
        break;
      default:
        timestampString = null;
    }
    if (timestampString != null) {
      return ZonedDateTime.parse(timestampString, DateTimeFormatter.ISO_ZONED_DATE_TIME);
    }
    return null;
  }
}

enum EventType {
  PUSH,
  COMMIT_COMMENT,
  PULL_REQUEST_REVIEW_COMMENT,
  OTHER,
  NON_GITHUB_EVENT
}

PImage currentImage = null;
Event currentEvent = null;

void draw() {
  background(0);
  Event newEvent = eventQueue.poll();
  if(newEvent != null) {
    currentEvent = newEvent;
    // Load a soundfile from the /data folder of the sketch and play it back
    System.out.println(newEvent.eventType);
    // System.out.println(newEvent.data);
    SoundFile file = null;
    switch(newEvent.eventType){
      case PUSH:
        file = windchimes[rand.nextInt(windchimes.length)];
        break;
      default:
        file = pianoSamples[rand.nextInt(pianoSamples.length)];
    }
    if (file != null) {
      file.play();
    }
    // Load the avatar image
    currentImage = loadImage(newEvent.userAvatar(), "png");
  }
  if (currentImage != null) {
    image(currentImage, 0, 0, 200, 200);
  }
  if (currentEvent != null) {
    int textSize = 32;
    textSize(textSize);
    fill(255);
    text(currentEvent.userLogin(), 200, 100);
    text(currentEvent.repository(), 0, 200+textSize);
    text(currentEvent.eventType.toString(), 0, 300+textSize);
    if (currentEvent.timestamp() != null) {
      String time = timeAgo.timeAgo(currentEvent.timestamp().toEpochSecond()*1000);
      text(time, 0, 300+textSize*2+10);
    }
  }
}
