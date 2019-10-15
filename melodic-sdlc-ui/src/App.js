import React, {Component} from "react";
import socketIOClient from "socket.io-client";
import {Howl, Howler} from 'howler';

Howler.volume(1);

const chimes = [
  new Howl({ src: ['/sound/n_C4.mp3']}),
  new Howl({ src: ['/sound/n_C5.mp3']}),
  new Howl({ src: ['/sound/n_D4.mp3']}),
  new Howl({ src: ['/sound/n_D5.mp3']}),
  new Howl({ src: ['/sound/n_E5.mp3']}),
  new Howl({ src: ['/sound/n_F4.mp3']}),
  new Howl({ src: ['/sound/n_G4.mp3']})];

class App extends Component {
    constructor() {
        super();
        this.state = {
            lastEvent: {},
            endpoint: "http://127.0.0.1:4001"
        };
    }

    componentDidMount() {
        const {endpoint} = this.state;
        //Very simply connect to the socket
        const socket = socketIOClient(endpoint);
        //Listen for data on the "outgoing data" namespace and supply a callback for what to do when we get one. In this case, we set a state variable
        socket.on("webhook", data => {
          this.setState({lastEvent: data});
          chimes[Math.floor(Math.random()*chimes.length)].play();
        });
    }

    render() {
        const {lastEvent} = this.state;
        console.log(lastEvent);
        return (
            <div style={{textAlign: "center"}}>
                <p>{lastEvent.event ? lastEvent.event : 'Waiting for new event'}</p>
                <p>{lastEvent.payload ? lastEvent.payload.repository.full_name : ''}</p>
            </div>
        )
    }
}

export default App;