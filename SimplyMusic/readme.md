# Simply Music
## Version: 1.0

This project is an app version of the old YouTube2MP3.com-style websites where you would input a YouTube URL and it would
return the audio file from the video.  
Simply Music utilizes the same concept to extract the audio file from a YouTube video, saving the file as a .m4a or .mp3 file for iOS devices, or as a .webm for Android devices. IOS devices cannot play the higher quality .webm audio files by default, unfortunately.
The files are saved to the disk, while the metadata is saved via SQFlite to a local database, which holds a reference pointer to each file
respectively.

The app is constructured as a music player app, which allows the user to create playlists, edit the metadata of the audio files (as it is impossible to expect correct artists or genres to be extracted from random YouTube video titles), and of course play the audio. The audio also works in the background after exiting the app. 

This app is a basic, completed version. There are quite a few quality of life changes I'd like to make, as well as making the code cleaner, however I wanted to be done so I apologize for getting a bit lazy. I'll attempt changes in the future after I get annoyed with how much better the basic features could be :P
