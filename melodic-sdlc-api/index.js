const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
var createHandler = require('github-webhook-handler')
var handler = createHandler({ path: '/webhook', secret: 'secret' })

//Port from environment variable or default - 4001
const port = process.env.PORT || 4001;

const server = http.createServer(function (req, res) {
  handler(req, res, function (err) {
    res.statusCode = 404
    res.end('no such location')
  })
})

const io = socketIo(server);

//Setting up a socket with the namespace "connection" for new sockets
io.on("connection", socket => {
    console.log("New client connected");

    //Here we listen on a new namespace called "incoming data"
    socket.on("incoming data", (data)=>{
        //Here we broadcast it out to all other sockets EXCLUDING the socket which sent us the data
       socket.broadcast.emit("outgoing data", {num: data});
    });

    //A special namespace "disconnect" for when a client disconnects
    socket.on("disconnect", () => console.log("Client disconnected"));
});

handler.on('error', function (err) {
  console.error('Error:', err.message)
});

handler.on('*', function (event) {
  console.log('Received a %s event in repo %s',
      event.event,
      event.payload.repository.full_name);
  io.emit('webhook', event);
});

server.listen(port, () => console.log(`Listening on port ${port}`));