import React, {Component} from "react";
import socketIOClient from "socket.io-client";

class App extends Component {
    constructor() {
        super();
        this.state = {
            response: 0,
            endpoint: "http://127.0.0.1:4001"
        };
    }

    componentDidMount() {
        const {endpoint} = this.state;
        //Very simply connect to the socket
        const socket = socketIOClient(endpoint);
        //Listen for data on the "outgoing data" namespace and supply a callback for what to do when we get one. In this case, we set a state variable
        socket.on("webhook", data => this.setState({response: data.num}));
    }

    render() {
        const {response} = this.state;
        console.log(response);
        return (
            <div style={{textAlign: "center"}}>
                <p>{response}</p>
            </div>
        )
    }
}

export default App;