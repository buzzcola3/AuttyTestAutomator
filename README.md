# Autty

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

TODO:
- implement: hard define types of execute responses: float, int, string (in a nice structure) in sync with Websocket_Device_Framework for easier result handling
- implement: 3 execute result types, "SUCCESS", "FAIL", "ERROR"
- implement: message state, i.e wsMessage can be "pending execution", "executing", "executed"
- implement: selectable outPort type... i.e: trigger next node on "done", on "start", on "execution start"
- implement: make nodes a class, with predefined enums for color, type, params --> and it, has a member to generate the json representation

- implement: make status colors on files and message type colors be vertical pill shaped color dots
- implement: user action node (user gets prompted to decide, measure something or similar)

- fix: clickable area of inPort/outPort not to be cut by the edge of the node
- fix: device reconnection
- fix: IU error when device disconnects
- fix: overflow in manual device add menu on some screens

- implement: device list svg icon
- implement: delete playground warning
- implement: load playground gives a hint to save unless the playground is empty
- implement: ctrl/shift selection on playground files (delete, run)