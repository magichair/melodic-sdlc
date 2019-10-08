# Melodic SDLC

A project intended to listen to github (and other) webhooks and generate a melody based on the events received.


# Getting Started

- Download Processing 3 from https://processing.org/download/
- Install JDK and maven `brew install maven`
- Use maven to fetch the project's dependencies `mvn dependency:copy-dependencies`. This will put the jars in the special location that Processing wants to find 3rd party code.
- Open `melodicsdlc.pde` in Processing.
- Hit the "Play" button to run start the server listening on `http://localhost:8080/webhook`
- Start `ngrok http 8080` to create an easy to reference ngrok endpoint.
- Update your Github webhook to point to your https ngrok endpoint.
- You should start receiving webhooks from Github!
