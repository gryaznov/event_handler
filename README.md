# EventHandler

|   | **Receiver**                 | **TcpPostman**                  |
|:-:|:---------------------------- |:--------------------------------|
| 0 | start                        | start                           |
| 1 | receive an API request       |                                 |
| 2 | validate the request         |                                 |
| 3 | pass request to `TcpPostman` | convert to protobuf             |
| 4 | return response, done        | establish TCP connection        |
| 5 |                              | send the event (with retries)   |
| 6 |                              | close the connection, write log |
