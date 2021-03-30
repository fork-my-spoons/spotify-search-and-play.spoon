# Spotify Search and Play

A spotlight-like search for spotify, allow searching albums, artists, playlists and tracks and playing the selected item on Spotify client for macOS:

![screenrecord](./screenshots/screenrecord.gif)

Note that after restarting hammerspoon the default search type will be reset to tracks.

# Installation

This app uses Spotify's search API, so you need to create a developer account in order to use it, go to [Developer Dashboard](https://developer.spotify.com/dashboard/) and register, then create a client id and a secret.

 - install [Hammerspoon](http://www.hammerspoon.org/) - a powerfull automation tool for OS X
   - Manually:

      Download the [latest release], and drag Hammerspoon.app from your Downloads folder to Applications.
   - Homebrew:

      ```brew install hammerspoon --cask```

 - download [spotify-search-and-play.spoon](https://github.com/fork-my-spoons/gitlab-merge-requests.spoon/raw/master/gitlab-merge-requests.spoon.zip), unzip and double click on a .spoon file. It will be installed under `~/.hammerspoon/Spoons` folder.
 
 - open ~/.hammerspoon/init.lua and add the following snippet, adding your parameters:

```lua
-- Spotify search and play
hs.loadSpoon("spotify-search-and-play")
spoon['spotify-search-and-play']:setup({
  client_id = '<your client id>',
  secret = '<your secret>'
})
spoon['spotify-search-and-play']:bindHotkeys({
    show={{"alt"}, "S"}}
)
```

The above config will set up <kbd>⌥</kbd> + <kbd>s</kbd> to open the app. 