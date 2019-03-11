# podman-compose
A gem to implement docker-compose-ish functionality for podman

*DISLAIMER*
This is very much not ready, consider it pre-alpha. It handles most things (mounting of voumes, mapping ports, naming based off of directory), but not more advanced settings such as custom network options.

If all you use `docker-compose` for is spinnup up multiple containers with mounts/ports, this will work great for you! 
