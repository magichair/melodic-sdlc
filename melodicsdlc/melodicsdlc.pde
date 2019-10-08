
import processing.sound.*;
import java.util.Random;
import org.rapidoid.setup.On;
import org.rapidoid.http.ReqHandler;
import org.rapidoid.http.Req;
import com.github.kevinsawicki.timeago.TimeAgo;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

import java.util.concurrent.ConcurrentLinkedQueue;

Random rand;
SoundFile[] windchimes;
SoundFile[] pianoSamples;
ConcurrentLinkedQueue<Event> eventQueue;
HashMap<String, PImage> avatarImageCache;
TimeAgo timeAgo;


float spring = 0.05;
float gravity = 0.03;
float friction = -0.9;
final int EVENT_DIAMETER = 150; 

void setup() {
  fullScreen();
  //size(800, 800);
  surface.setTitle("Melodic SDLC");
  surface.setResizable(true);
  
  rand = new Random(System.currentTimeMillis());
  eventQueue = new ConcurrentLinkedQueue<Event>();
  avatarImageCache = new HashMap<String, PImage>();
  timeAgo = new TimeAgo();
  
  pianoSamples = new SoundFile[]{
    new SoundFile(this, "piano_C4.mp3")//,
    //new SoundFile(this, "piano_C5.mp3"),
    //new SoundFile(this, "piano_D5.mp3"),
    //new SoundFile(this, "piano_E5.mp3"),
    //new SoundFile(this, "piano_G4.mp3")
  };
  windchimes = new SoundFile[]{
    new SoundFile(this, "n_C4.mp3")//,
    //new SoundFile(this, "n_C5.mp3"),
    //new SoundFile(this, "n_D4.mp3"),
    //new SoundFile(this, "n_D5.mp3"),
    //new SoundFile(this, "n_E5.mp3"),
    //new SoundFile(this, "n_F4.mp3"),
    //new SoundFile(this, "n_G4.mp3")
  };
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
      SoundFile file = null;
      switch(event.eventType){
        case PUSH:
          file = windchimes[rand.nextInt(windchimes.length)];
          break;
        default:
          file = pianoSamples[rand.nextInt(pianoSamples.length)];
      }
      if (file != null) {
        file.play();
      }
      eventQueue.add(event);
      return "";
    }
  });
}

class Event {
  EventType eventType;
  JSONObject data;
  
  float x, y;
  int diameter;
  float vx = 0;
  float vy = 0;
  
  public Event(EventType eventType, JSONObject data) {
    this.eventType = eventType;
    this.data = data;
    this.x = rand.nextInt(width);
    this.y = 0;
    this.diameter = EVENT_DIAMETER;
    this.vx = rand.nextFloat() - 0.5f;
  }
  
  void collide(int id, Event[] others) {
    for (int i = id + 1; i < others.length; i++) {
      float dx = others[i].x - x;
      float dy = others[i].y - y;
      float distance = sqrt(dx*dx + dy*dy);
      float minDist = others[i].diameter/2 + diameter/2;
      if (distance < minDist) { 
        float angle = atan2(dy, dx);
        float targetX = x + cos(angle) * minDist;
        float targetY = y + sin(angle) * minDist;
        float ax = (targetX - others[i].x) * spring;
        float ay = (targetY - others[i].y) * spring;
        vx -= ax;
        vy -= ay;
        others[i].vx += ax;
        others[i].vy += ay;
      }
    }   
  }
  
  void move() {
    vy += gravity;
    x += vx;
    y += vy;
    if (x + diameter/2 > width) {
      x = width - diameter/2;
      vx *= friction; 
    }
    else if (x - diameter/2 < 0) {
      x = diameter/2;
      vx *= friction;
    }
    if (y + diameter/2 > height) {
      y = height - diameter/2;
      vy *= friction; 
    } 
    else if (y - diameter/2 < 0) {
      y = diameter/2;
      vy *= friction;
    }
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
  
  public PImage getUserAvatarImage() {
    String userAvatarUrl = userAvatar();
    PImage image = null;
    if (userAvatarUrl != null) {
      image = avatarImageCache.get(userAvatarUrl);
      if (image == null) {
        image = loadImage(userAvatarUrl, "png");
        avatarImageCache.put(userAvatarUrl, image);
      }
    }
    if (image != null) {
      image.resize(diameter, diameter);
    }
    return image;
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
    }
    if (timestampString != null) {
      return ZonedDateTime.parse(timestampString, DateTimeFormatter.ISO_ZONED_DATE_TIME);
    }
    return null;
  }
  
  public void display() {
    //int textSize = 32;
    //textSize(textSize);
    //fill(255);
    //text(userLogin(), 200, 100);
    //text(repository(), 0, 200+textSize);
    //text(eventType.toString(), 0, 300+textSize);
    //if (timestamp() != null) {
    //  String time = timeAgo.timeAgo(timestamp().toEpochSecond()*1000);
    //  text(time, 0, 300+textSize*2+10);
    //}
    
    // Image Mask + UserAvatarImage
    // create mask
    PGraphics maskImage;
    maskImage = createGraphics(diameter, diameter);
    maskImage.beginDraw();
    maskImage.ellipseMode(CORNER);
    maskImage.ellipse(0, 0, diameter, diameter); //x,y is relative to the maskImage
    maskImage.endDraw();
    
    PImage img = getUserAvatarImage();
    img.mask(maskImage); 
    image(img, x, y, diameter, diameter);
  }
}

enum EventType {
  PUSH,
  COMMIT_COMMENT,
  PULL_REQUEST_REVIEW_COMMENT,
  OTHER,
  NON_GITHUB_EVENT
}

static int MAX_QUEUE_SIZE = 20;

void draw() {
  background(0);
  if (eventQueue.size() > MAX_QUEUE_SIZE) {
    eventQueue.poll(); // Remove to get below queue size
  }
  Event[] eventList = new Event[eventQueue.size()];
  eventList = eventQueue.toArray(eventList);
  for (int i = 0; i < eventList.length; i++) {
    Event event = eventList[i];
    if (event != null) {
      event.collide(i, eventList);
      event.move();
      event.display();
    }
  }
}
