# Firebox
A script that allows you to create a portable Firefox profile that you can sync anywhere, e.g with Seafile or Owncloud or Dropbox or some app alike, allowing you to remote kill other instances to prevent corruption of the profile.

Why would you do this?
 - Have one or more Firefox instance per web project so you can have one or more simulated users, and easily share and document this environment
 - Run multiple Firefox instances at the same time (they do not interfere with eachother or the main Firefox process on the system)
 - Have a privacy-oriented separate Firefox instance used just for webcommunication and such (ala Rambox, Franz, etc)

This is not a very complicated script and should be understandable to everyone. The core of it is just running `/usr/lib/firefox/firefox --profile ./ffprofile --no-remote`. You can find it [here](https://github.com/xarinatan/Firebox/blob/2e5b7378fd85703be58e5e7ffa3e04fb79320a0f/firestarter.sh#L55). The rest is just fluff to prevent corruption and weirdness :)
