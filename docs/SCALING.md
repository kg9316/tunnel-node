# Scaling notes

Current repo reflects the server exactly as exported:
- OpenSSH on 22 and 443
- registry builder on a systemd timer
- HTTP registry UI on localhost:8080 behind nginx
- device admin UI on localhost:8081 behind nginx
- fixed public relay port range planned for 40001-50001

With the current architecture, a practical first production target is a few hundred devices per node.
The next major scaling step is replacing per-device relay processes with a single relay daemon.

Recommended progression:
1. Stabilize this node layout.
2. Add relay state visibility.
3. Replace per-device relay helpers with a single TCP relay service.
4. Add a control-plane service for multi-node scheduling.
