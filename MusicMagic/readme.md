# Music Magic
## (WIP)

This project is an app version of the old YouTube2MP3.com-style websites where you would input a YouTube URL and it would
return the audio file from the video.  
Music Magic utilizes the same concept to extract the audio file from a YouTube video, saving the file as a .m4a or .mp3 file for iOS devices,
or as a .webm for Android devices. IOS devices cannot play the higher quality .webm audio files by default, unfortunately.
The files are saved to the disk, while the metadata is saved via SQFlite to a local database, which holds a reference pointer to each file
respectively.

The app is constructured as a music player app, which allows the user to create playlists, edit the metadata of the audio files (as it is impossible to 
to expect correct artists or genres to be extracted from random YouTube videos), and of course play the audio. The audio also works in the background after exiting
the app. 

This app is still a work in progress (WIP).
