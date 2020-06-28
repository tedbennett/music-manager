# music-manager (unnamed)

### I'm going to take a break from developing this app to focus on just the track conversion part in another repo. 

This is an app to share music between Apple Music and Spotify.

Moving between these music services can be a pain - not only do you need to migrate your music library, but it is also much more difficult to share music.

The goal of the app is to provide a platform to easily migrate a user's playlists and library between the platforms, and to help convert track and album links.

## Current status

Users can give authorisation to the app to access both services. Playlists from each service are downloaded and displayed with their information and artwork.
Link conversion for tracks works, as does playlist transfer from Spotify to AM.

## Issues

### Rate Limiting issues
Each platform uses unique ids for song, album etc. resources, and these can be converted using an ISRC number. This number refers to a particular recording of a song.

Unfortunately there is no such number for albums so another strategy will need to be used.

There is no way to convert isrc numbers to track ids on either platform without needing to send a request for each song (Apple music allows search with ISRC of up to 25 numbers, however each ISRC can refer to multiple tracks (e.g single, album versions) so this not particularly helpful.
Hence converting a playlist from Apple Music to Spotify is possible up until a playlist size of ~50 tracks, at which point the Too Many Requests error starts to appear.

The solution would be to slow down playlist creation, this will take a bit of work.

### Async Images
Downloading images for albums and playlists can be pretty funky. I haven't implemented an effective cache for images, and they seem to be messing with the navigation views (particularly the large titles). Ideally an image would be associated with an album object, which would prevent the need to download duplicate images.

## To-do

- Transfer playlists from AM to Spotify
  - needs spotify user id
- Nice UI for track conversion
- New add service screen
- Add to Library from track conversion view.
- Rework Async images
