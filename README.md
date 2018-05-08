# VAGMusic (Treble)
Simple iOS Music Player

> "Something simple and func I made a while back; decided it was time to open source it. The only reason this app exists was because my dock blocks my iPhone's speakers, and since the native Music app doesn't support Landscape, I decided to write a nicer app with Landscape support." - meteochu

Meteochu wrote a basic landscape music player that works well, which I repurposed for art gallery/kiosk purposes. iPad only. iCloud removed. Queue popover was rejigged, and queue-loading was rewritten. App tries to autoload a playlist in your Music library called "Treble" and if it can't be discovered or its empty, you can use the Music Picker like usual. Music Picker access is locked when in Guided Access mode.

Apps can't access the central music queue when its loaded from elsewhere, so I have the app reset the queue to the Treble Playlist on every reopen. Annoying functionality for most, disable if not using as a basic kiosk.
