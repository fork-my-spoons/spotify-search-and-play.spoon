local obj = {}
obj.__index = obj

-- Metadata
obj.name = "spotify-search-and-play"
obj.version = "1.0"
obj.author = "Pavel Makhov"
obj.homepage = "https://fork-my-spoons.github.io/"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.refresh_token_req_header = nil
obj.token = nil
obj.token_expires_at = nil
obj.choose = nil
obj.delayed_timer = nil
obj.item_type_to_search = nil
obj.iconPath = hs.spoons.resourcePath("icons")

local user_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }})
local number_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }})
local track_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }})


function obj:refresh_token()
    local status, body = hs.http.post('https://accounts.spotify.com/api/token', 
        'grant_type=client_credentials', 
        { Authorization = 'Basic ' .. self.refresh_token_req_header})
    
    local response = hs.json.decode(body)
    self.token = response.access_token
    self.token_expires_at = os.time() + response.expires_in
end


function obj:get_auth_header()
    if self.token == nil or os.difftime(self.token_expires_at, os.time()) < 0 then
        self:refresh_token()
    end
    
    return {Authorization = 'Bearer ' ..self.token}
end


function obj:build_list(body)
    local result = {}

    if self.item_type_to_search == 'track' then
        local tracks = hs.json.decode(body).tracks.items
        for _, track in ipairs(tracks) do
            table.insert(result, {
                image = hs.image.imageFromURL(track.album.images[3].url),
                text = track.name,
                subText = track.album.name .. '   ' .. track.artists[1].name,
                spotify_id = track.uri
            })
        end
    elseif self.item_type_to_search == 'artist' then
        local artists = hs.json.decode(body).artists.items
        for _, artist in ipairs(artists) do
            local image
            if #artist.images == 3 then image = hs.image.imageFromURL(artist.images[1].url)
            elseif #artist.images == 0 then image = nil 
            else hs.image.imageFromURL(artist.images[1].url) 
            end

            table.insert(result, {
                image = image,
                text = artist.name,
                spotify_id = artist.uri
            })
        end
    elseif self.item_type_to_search == 'playlist' then
        local playlists = hs.json.decode(body).playlists.items
        for _, playlist in ipairs(playlists) do
            table.insert(result, {
                image = hs.image.imageFromURL(playlist.images[1].url),
                text = playlist.name,
                subText = track_icon .. playlist.tracks.total .. '   by ' .. playlist.owner.display_name,
                spotify_id = playlist.uri
            })
        end
    elseif self.item_type_to_search == 'album' then
        local albums = hs.json.decode(body).albums.items
        for _, album in ipairs(albums) do
            table.insert(result, {
                image = hs.image.imageFromURL(album.images[3].url),
                text = album.name,
                subText = user_icon .. album.artists[1].name,
                spotify_id = album.uri
            })
        end
    end

    return result
end


function obj:queryChangedCallbackDelayed()
    self.delayer_timer:start()
end


function obj:queryChangedCallback()
    local str = self.chooser:query()
    if string.len(str) < 3 then return self.chooser end

    local res = {}
    local url = 'https://api.spotify.com/v1/search?q=' .. hs.http.encodeForQuery(str) .. '&type=' .. self.item_type_to_search
    status, body = hs.http.get(url, self:get_auth_header())

    local res = self:build_list(body)

    return self.chooser:choices(res)
end


function obj:init()
    self.chooser = hs.chooser.new(function(item)
        if item ~= nil then
            hs.spotify.playTrack(item.spotify_id)
        end
    end)

    self.chooser:searchSubText(true)
    
    self.chooser:queryChangedCallback(hs.fnutils.partial(self.queryChangedCallbackDelayed, self))
    self.chooser:hideCallback(function() 
        self.chooser:choices(nil) 
        self.chooser:query(nil)
    end)

    self.delayer_timer = hs.timer.delayed.new(1, function() self:queryChangedCallback() end)

    t = require("hs.webview.toolbar")
    a = t.new("myConsole", {
            { id = "album", selectable = true, image = hs.image.imageFromPath(obj.iconPath ..  '/compact-disc.png'):template(true)},
            { id = "artist", selectable = true, image = hs.image.imageFromPath(obj.iconPath ..  '/microphone.png'):template(true)},
            { id = "playlist", selectable = true, image = hs.image.imageFromPath(obj.iconPath ..  '/playlist.png'):template(true)},
            { id = "track", selectable = true, image = hs.image.imageFromPath(obj.iconPath ..  '/musical-note.png'):template(true)},
        }):canCustomize(true)
          :autosaves(true)
          :selectedItem("track")
          :sizeMode("small")
          :setCallback(function(toolbar, chooser, identifier)
                            self.item_type_to_search = identifier
                            self:queryChangedCallback()
                       end)
    
    t.attachToolbar(a)

    self.chooser:attachedToolbar(a)


end


function obj:setup(args)
    self.refresh_token_req_header = hs.base64.encode(args.client_id .. ':' .. args.secret)
    self.item_type_to_search = args.default_search_type or 'track'
end

function obj:show()
    self.chooser:show()
end

function obj:bindHotkeys(mapping)
    local spec = {
        show = hs.fnutils.partial(self.show, self),
      }
      hs.spoons.bindHotkeysToSpec(spec, mapping)
      return self
end

return obj