

AUTHENTICATE_TUBER = function() { 
  # Autentication — uses Client ID, Client Secret from Google Cloud
  # https://console.cloud.google.com/auth/clients?project=chromeextension-1606581122438
  YOUTUBE_CLIENT_ID = Sys.getenv("YOUTUBE_CLIENT_ID")
  YOUTUBE_CLIENT_SECRET = Sys.getenv("YOUTUBE_CLIENT_SECRET")
  YOUTUBE_CHANNEL_ID = Sys.getenv("YOUTUBE_CHANNEL_ID")
  YOUTUBE_API_KEY = Sys.getenv("YOUTUBE_API_KEY")
  
  setwd("./oauth_tuber")
  tuber::yt_oauth(YOUTUBE_CLIENT_ID,YOUTUBE_CLIENT_SECRET)
  tuber::yt_set_key(YOUTUBE_API_KEY)
  setwd("..")
  
  # stats = tuber::get_channel_details(channel_ids=YOUTUBE_CHANNEL_ID,simplify = TRUE)
  stats = tuber::get_my_channel(simplify = TRUE)
  
  profile = c(Avatar      = stats$thumbnail_url,
              Title       = stats$title,
              Description = stats$description,
              ChannelID   = stats$channel_id,
              Handle      = stats$custom_url,
              URL         = paste0("https://www.youtube.com/",stats$custom_url),
              Joined      = as.character( as.Date(stats$published_at) ),
              CountryCode = stats$country,
              Country     = countrycode::countrycode(stats$country, "iso2c", "country.name") ,
              Views       = stats$view_count,
              Subscribers = stats$subscriber_count,
              Videos      = stats$video_count
              )
  
  profile = data.frame(profile=profile)
  
  # avatarfull = imager::load.image(Avatar) It fails
  avatarfull = magick::image_read(profile["Avatar",])
  # avatarfull = magick::image_annotate(avatarfull, Title, 
  #                                 size = 30,         # Font size
  #                                 gravity = "north", # Position (top center)
  #                                 color = "black",   # Text color
  #                                 location = "+0+10") # Small offset from the top
  plot(avatarfull)
  
  # Save Avatar to file
  download.file(
    url      = stats$thumbnail_url,
    destfile = file.path("youtube_avatars",paste0(stats$custom_url,".jpeg")),
    mode     = "wb"
  )
  
  return(profile)
}


AUTHENTICATE_YTANALYTICS = function() {
  # file remove is now mandatory since we are working with 2 different packages that use the same .httr-oauth file.
  # file.remove(".httr-oauth")
  YOUTUBE_CLIENT_ID = Sys.getenv("YOUTUBE_CLIENT_ID")
  YOUTUBE_CLIENT_SECRET = Sys.getenv("YOUTUBE_CLIENT_SECRET")
  setwd("./oauth_ytanalytics")
  token = YTAnalytics::youtube_oauth(clientId = YOUTUBE_CLIENT_ID, clientSecret = YOUTUBE_CLIENT_SECRET)
  setwd("..")
  return(token) 
}


CREATE_SUBFOLDERS = function(playlist_title) {
  # Create subfolders for thumbnails and captions
  subfolders = c("youtube_thumbnails", "youtube_captions", "youtube_summaries", "youtube_summaries_html")
  
  for (subfolder in subfolders) {
    subfolder = file.path(subfolder,playlist_title)
    
    if ( dir.exists(subfolder) ) {
      cat("Subfolder already exists:", subfolder, "\n")
    } else {
      cat("Creating subfolder:", subfolder, "\n")
      dir.create(subfolder, recursive = TRUE)
      
    }
  }
   
}


DOWNLOAD_CAPTIONS = function(videos) {
  download_folder = file.path("youtube_captions",videos$playlist_title[1])
  
  # Download each caption
  for ( i in 1:nrow(videos) ) {
    file_name = videos$video_title[i]
    file_path = file.path(download_folder,paste0(file_name,".srt"))
    if ( file.exists(file_path) ) {
      cat("Caption already exists:", file_path, "\n") 
    } else {
      cat("Downloading caption:", file_path, "\n")
      captions = tuber::download_caption(
        caption_id = videos$caption_id[i], lang = videos$language[i], format = "sbv", as_raw = F
      )
      captions = gsub("[0-9]+:[0-9]{2}:[0-9]{2}\\.[0-9]{3},[0-9]+:[0-9]{2}:[0-9]{2}\\.[0-9]{3}", "",captions)
      captions = gsub("\u00A0", "", captions) # Remove non-breaking spaces
      # captions = gsub("(\r?\n)+", "\r\n", captions, perl = TRUE) # Remove multiple empty lines
      writeLines(captions, file_path)
      
    }
    
  }
  
}


DOWNLOAD_FROM_YOUTUBE = function(download) {
  list2env(setNames(as.list(download$download), rownames(download)), envir = environment())
  
  # example: https://www.youtube.com/playlist?list=OLAK5uy_lOq4NjXU5q4EN0BTR67iTW7e_g_3qa5jc
  if ( url_type == "playlist" ) {
    command = "./tools/yt-dlp.exe --extract-audio "
    command = paste0(command,"--audio-format mp3 --audio-quality 0 ")
    command = paste0(command,"-P '",OutputFolder,"' ")
    command = paste0(command,"-o '%(playlist_index)02d - %(title)s.%(ext)s' '")
    command = paste0(command,youtube_url,"'")
  } 
  
  # example: https://www.youtube.com/watch?v=6wo_iXimGGM
  if ( url_type == "video_with_chapters" ) {
    command = "./tools/yt-dlp.exe --extract-audio --split-chapters "
    command = paste0(command,"--audio-format mp3 --audio-quality 0 ")
    command = paste0(command,"-P '",OutputFolder,"' ")
    command = paste0(command,"--replace-in-metadata 'section_title' '^\\d+[\\.\\s-]+' '' ")
    command = paste0(command,"-o 'chapter:%(section_number)02d - %(section_title)s.%(ext)s' '")
    command = paste0(command,youtube_url,"'")
  }
  
  # example: https://www.youtube.com/watch?v=bvW6kN8cVXQ&list=RDbvW6kN8cVXQ&start_radio=1&rv=EQ8npjaGlV4
  if ( url_type == "video" ) {
    music_name = paste0(Artist," - ",Album,".mp3")
    
    command = "./tools/yt-dlp.exe --extract-audio "
    command = paste0(command,"--audio-format mp3 --audio-quality 0 ")
    command = paste0(command,"-P '",OutputFolder,"' ")
    command = paste0(command,"-o '",music_name,"' '")
    command = paste0(command,youtube_url,"'")
  }
  
  terminal_id = rstudiotools::terminal(command)
  
}


DOWNLOAD_FROM_YOUTUBE_ASK_VALUES = function(MusicFolder) {
  # MusicFolder = "C:/MEGA/Music"
  # youtube_url = "https://www.youtube.com/playlist?list=PL6ZNwyxUtD27vHO9BfveOM6lLzSBMb9tL"
  youtube_url = trimws( svDialogs::dlgInput("YouTube URL?", default = "")$res )
  youtube_url = sub("&.*", "", youtube_url)
  
  # if youtube_url contains "playlist?list="
  if (grepl("playlist?list=", youtube_url, fixed = TRUE)) {
    id = strsplit(youtube_url,"list=")[[1]][2]
    details = tuber::list_playlists(playlist_ids=id) 
    
    Album = details$title
    
    playlist_videos = tuber::get_playlist_video_ids(playlist_id = id,max_results = 500)
    video_details = tuber::get_video_details(video_ids = playlist_videos)
    Cover = video_details$snippet_thumbnails[[1]][["standard"]][["url"]]
    
    # video_stats = tuber::get_video_stats(video_ids = playlist_videos)
    
    Channel = details$channel_title
    url_type = "playlist"
    
  } else {
  # individual video  
    id = strsplit(youtube_url,"v=")[[1]][2]
    details = tuber::get_video_details(video_id = id)
    
    Album = details$snippet_title[1]
    thumbnails = details$snippet_thumbnails[1]
    Cover = thumbnails[[1]][["standard"]][["url"]] 
    
    Channel = details$snippet_channelTitle[1]
    url_type = "video"
    
    # Check for chapters
    desc = details$snippet_description[1]
    # Regex to find timestamps (e.g., 0:00, 12:34, 1:02:03)
    # It checks for at least two timestamps, as YouTube requires 3+ for chapters
    if ( stringr::str_count(desc, "\\d{1,2}:\\d{2}") >= 3 ) url_type = "video_with_chapters"
  }
  
  # cat( cli::rule(left = url_type, col = "blue"),"\n" )
  
  img = magick::image_read(Cover) 
  # print(img) - In the Viewer Pane - doesn't scale
  plot(img) # In the Plot pane - scales better
  
  Artist = trimws( svDialogs::dlgInput("Album Artist?", default = Channel)$res )
  Album = sub("^Album - ", "", Album)
  Album = trimws( svDialogs::dlgInput("Album Name?", default = Album)$res )
  AlbumFolder = paste0(Artist," - ",Album)
  AlbumFolder = SANITIZE_FILENAME(AlbumFolder)
  OutputFolder = paste0(MusicFolder,"/",AlbumFolder)
 
  download = c(MusicFolder = MusicFolder,
               youtube_url = youtube_url,
               url_type = url_type,
               Artist = Artist,
               Album = Album,
               Cover = Cover,
               AlbumFolder = AlbumFolder,
               OutputFolder = OutputFolder
               )
             
  download = data.frame(download=download)
  print(download)
  
  return(download)
}


DOWNLOAD_FROM_YOUTUBE_CREATE_FOLDER = function(download) {
  list2env(setNames(as.list(download$download), rownames(download)), envir = environment())
  
  # Create OutputFolder
  fs::dir_create(OutputFolder)
  
  cat("Create Folder   :", AlbumFolder, "\n")
  
  # Save Cover
  if ( download["url_type",] == "video" ) {
    cover = paste0(AlbumFolder,".jpg")
  } else {
    cover = "00.jpg"
  }
  
  filename = paste0(OutputFolder,"/",cover)
  utils::download.file(url=Cover,destfile=filename,mode = "wb")
  cat("Save Cover      :", cover, "\n")
  
  # Save youtube_url
  # (echo [InternetShortcut] & echo URL=https://www.youtube.com/watch?v=EQ8npjaGlV4) > "Analog Dreams - Tangerine Dream Tribute.url"
  url = paste0(AlbumFolder,".url")
  filename = paste0(OutputFolder,"/",url)
  filecontents = paste0("[InternetShortcut]\nURL=",youtube_url)
  writeLines(filecontents,filename)
  cat("Save YouTube URL:", url, "\n")
}


DOWNLOAD_FROM_YOUTUBE_INSERT_METADATA = function(download) {
  list2env(setNames(as.list(download$download), rownames(download)), envir = environment())
  
  if ( url_type == "video" ) {
    cover = file.path(OutputFolder,paste0(AlbumFolder,".jpg"))
  } else {
    cover = file.path(OutputFolder,paste0(AlbumFolder," - 00.jpg"))
  }
  
  mp3tags = list.files(OutputFolder,pattern = "\\.mp3$",full.names = FALSE)
  mp3s = list.files(OutputFolder,pattern = "\\.mp3$",full.names = TRUE)
  
  i = 1
  for (i in 1:length(mp3s)) {
    f = mp3s[i]
    tags = mp3tags[i]
    parts = unlist( stringr::str_split(tags, "-") )
    Track = as.integer(trimws( parts[3] ) )
    Title = trimws( parts[4] )
    Title = tools::file_path_sans_ext(Title)
    
    temp = tempfile(fileext = ".mp3")
    
    cmd = sprintf(
      paste(
        'ffmpeg -y',
        '-i "%s"',
        '-i "%s"',
        '-map 0:a',
        '-map 1',
        '-c copy',
        '-id3v2_version 3',
        '-metadata artist="%s"',
        '-metadata album_artist="%s"',
        '-metadata album="%s"',
        '-metadata title="%s"',
        '-metadata track="%s"',
        '-metadata:s:v title="Cover"',
        '-metadata:s:v comment="Cover (front)"',
        '"%s"'
      ),
      f, cover, Artist, Artist, Album, Title, Track, temp
    )
    
    system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
    file.copy(temp, f, overwrite = TRUE)
    unlink(temp)
    cat("Inserting Metadata in", basename(f), "\n")
  }
}


DOWNLOAD_FROM_YOUTUBE_MASS_RENAME = function(download) {
  list2env(setNames(as.list(download$download), rownames(download)), envir = environment())
  
  if ( url_type == "video" ) {
    cat("No need to rename a single video\n")
    return(invisible()) # No need to rename a single video
  }
   
  prefix = paste0(AlbumFolder," - ")
  command = paste0("Get-ChildItem '",OutputFolder,"/*' | ")
  command = paste0(command,"Where-Object { $_.BaseName -match '^\\d{2}' } | ")
  command = paste0(command,"Rename-Item -NewName { '",prefix,"' + $_.Name }")
  terminal_id = rstudiotools::terminal(command)
  
}


DOWNLOAD_SUMMARIES_FROM_LMSTUDIO = function(videos) {
  playlist_title = videos$playlist_title[1]
  folder_captions = file.path("youtube_captions",playlist_title)
  folder_summaries = file.path("youtube_summaries",playlist_title)
  folder_summaries_html = file.path("youtube_summaries_html",playlist_title)
  prompt = "Give me the main topics of the following text in portuguese, with no more than 10 topics and no title. Format the result as a numbered list: "
  
  # Download each summary
  for ( i in 1:nrow(videos) ) {
    file_name = videos$video_title[i]
    path_captions = file.path(folder_captions,paste0(file_name,".srt"))
    path_summaries = file.path(folder_summaries,paste0(file_name,".txt"))
    path_summaries_html = file.path(folder_summaries_html,paste0(file_name,".html"))
    
    if ( file.exists(path_summaries) ) {
      cat("Summary already exists:", path_summaries, "\n") 
    } else {
      cat("Downloading summary:", path_summaries, "\n")
      
      captions = readLines(path_captions, warn = FALSE)
      captions = c(prompt,captions)
      captions = paste(captions,collapse = " ")
      # minifunctions::editvariable(captions)
      
      video_summary = aitools::lmstudio(prompt=captions)
      video_summary = paste0(file_name, "\n", video_summary)
      writeLines(video_summary,path_summaries)
      
      Report = data.frame(Video = videos$video_thumbnail[i], Summary = video_summary, stringsAsFactors = F) 
      html = minifunctions::printdataframe(Report,expand_images = T)
      writeLines(html,path_summaries_html)
      
    }
  }
}


DOWNLOAD_THUMBNAILS = function(videos) {
  file_paths = vector()
  
  ncol = ceiling(sqrt(nrow(videos)))
  nrow = ceiling(nrow(videos)/ncol)
  
  download_folder = file.path("youtube_thumbnails",videos$playlist_title[1])
  
  # Download each image and store the file paths
  for ( i in 1:nrow(videos) ) {
    url = videos$video_thumbnail[i]
    file_name = videos$video_title[i]
    file_path = file.path(download_folder,paste0(file_name,".jpg"))
    if ( file.exists(file_path) ) {
      cat("Thumbnail already exists:", file_path, "\n") 
    } else {
      cat("Downloading thumbnail:", file_path, "\n")
      download.file(url, file_path, mode = "wb")
    }
    file_paths = c(file_paths,file_path)
  }
  
  # Read the images using magick
  images = lapply(file_paths, magick::image_read)
  
  # Combine the images into a grid
  grid_image = magick::image_montage(
    do.call(c, images),
    tile = paste(ncol, nrow, sep = "x"), 
    geometry = "320x180+10+10"
  )
  
  # Display the grid image
  print(grid_image)
}


EVOLUTION_OF_MY_VIEWS = function(fromDate="2018-10-20") {
  
  # Start working with YTAnalytics package 
  token = AUTHENTICATE_YTANALYTICS()
  
  Views = YTAnalytics::channel_stats(
    metrics = "views",
    dimensions = "day",            
    startDate = "2018-10-20",     
    endDate = as.character(Sys.Date()), 
    token = token,
    sort = "day",
    maxResults = 10000
  )
  
  Views$cumulative_views = cumsum(Views$views)
  Views$views = NULL
  Views$Date = as.Date(Views$day)
  Views$day = NULL
  Views = Views[,c(2,1)]
  
  # EVOLUTION OF UPLOADED VIDEOS OVER TIME 
  Uploads = data.frame(Date = videos$video_published,Video = videos$video_title)
  Uploads = Uploads[order(Uploads$Date), ] 
  rownames(Uploads) = NULL
  
  Uploads = Uploads |>
    dplyr::count(Date, name = "uploads") |>      
    dplyr::arrange(Date) |>
    dplyr::mutate(cumulative_uploads = cumsum(uploads))
  
  Uploads$uploads = NULL
  
  # Filter fromDate
  Views = Views[Views$Date >= fromDate, ]
  Uploads = Uploads[Uploads$Date >= fromDate, ]
  
  # PLOTLY DUAL AXIS 
  
  p = plotly::plot_ly() |>
    
    # LEFT Y AXIS - cumulative views
    plotly::add_lines(
      data = Views,
      x = ~Date,
      y = ~cumulative_views,
      name = "Cumulative Views",
      yaxis ="y",
      line = list(width = 3)
    ) |>
    
    # RIGHT Y AXIS - cumulative uploads
    plotly::add_lines(
      data = Uploads,
      x = ~Date,
      y = ~cumulative_uploads,
      name = "Cumulative Uploads",
      yaxis = "y2",
      line = list(width = 3)
    ) |>
    
    plotly::layout (
      title = list(
        text = "Cumulative Views and Uploads Over Time, for TugaStone Youtube Channel",
        font = list(size = 24),
        y = 0.93,
        x = 0.5,
        xanchor = "center"
      ),
      
      xaxis = list(
        title = "Date"
      ),
      
      yaxis = list(
        title = "Cumulative Views",
        side = "left"
      ),
      
      yaxis2 = list(
        title = "Cumulative Uploads",
        overlaying = "y",
        side = "right",
        tickpadding = 10  # space between ticks and axis
      ),
      
      legend = list(
        orientation = "h",
        x = 0.5,
        xanchor = "center",
        y = -0.15
      ),
      
      margin = list(
        t = 100,
        r = 100,
        l = 100
      )  
      
    )
  
  p
  
  
}


EVOLUTION_OF_PLAYLIST_VIEWS = function(playlist) {
  
  # Start working with YTAnalytics package 
  token = AUTHENTICATE_YTANALYTICS()
  
  Views = YTAnalytics::playlist_stats(
    playlistId = playlist,
    metrics = "views",
    dimensions = "day",            
    startDate = "2018-10-20",     
    endDate = as.character(Sys.Date()), 
    token = token,
    sort = "day",
    maxResults = 10000
  )
  
}


GET_CAPTIONS_FROM_PLAYLIST = function(playlist_id) {
  suppressMessages({
    playlist_videos = tuber::get_playlist_video_ids(playlist_id = playlist_id,max_results = 500)
  })
  # Create empty dataframe to store captions
  # asr stands for Automatic Speech Recognition
  captions = data.frame()
  for (id in playlist_videos) {
    cat(".")
    df = tuber::list_captions(video_id = id)
    captions = rbind(captions,df )
  } 
  cat(" ",length(playlist_videos),"videos,",nrow(captions),"captions") 
  cat("\n")
  
  return(captions)
}


GET_CHANNEL_PLAYLISTS = function(channel_id,exclude_playlists) {
  playlists = tuber::list_playlists(channel_id=channel_id,max_results = 500) 
 
  playlists = data.frame(playlist_id = playlists$playlist_id,playlist_title = playlists$title)
  
  # Create the regex pattern
  exclude_playlists = paste(exclude_playlists, collapse = "|")
  # Exclude playlists that match the pattern
  playlists = playlists[!grepl(exclude_playlists, playlists$playlist_title), ]
  # Sort by Playlist Title 
  playlists = playlists[ order(playlists$playlist_title), ]
  # Reset Row Numbers
  row.names(playlists) = NULL
  
  return(playlists)
}


GET_CHANNEL_VIDEOS = function(channel_id) {
  videos = tuber::list_channel_videos(channel_id=channel_id,max_results = 500)
  video_id = videos$video_id
  return( data.frame(video_id))
}


GET_PLAYLIST_TITLE = function(playlist_id) {
  # playlist_id = "PLRbCt61PaxX2d0_QXh6Qi6_jAQd66fmcI"
  playlist = tuber::list_playlists(
    playlist_ids = playlist_id,
    part = "snippet",
    simplify = FALSE
  )
  
  playlist_title = playlist$items[[1]]$snippet$title
  return(playlist_title)
}


GET_VIDEOS_FROM_PLAYLISTS = function(playlists) {
  playlist_title = vector()
  video_id = vector()
  video_title = vector()
  video_published = vector()
  video_views = vector()
  video_thumbnail = vector()
  video_url = vector()
 
  for ( i in 1:nrow(playlists) ) {
    playlistTitle = playlists$playlist_title[i]
    cat("Processing Playlist",i,"/",nrow(playlists),":",playlistTitle)
    
    suppressMessages({
      playlist_videos = tuber::get_playlist_video_ids(playlist_id = playlists$playlist_id[i],max_results = 500)
      video_details = tuber::get_video_details(video_ids = playlist_videos)
      video_stats = tuber::get_video_stats(video_ids = playlist_videos)
    })
    
    N = length(playlist_videos)
    cat(" ",N,"videos \n") 
    playlist_title = c(playlist_title,rep(playlistTitle,N))
    video_id = c(video_id,video_details$id)
    url = paste0("https://www.youtube.com/watch?v=",video_details$id)
    video_url = c(video_url,url)
    video_title = c(video_title,video_details$snippet_title)
    video_views = c(video_views,video_stats$view_count)
    video_published = c(video_published,video_details$snippet_publishedAt)
    video_thumbnail = c(video_thumbnail,sapply(video_details$snippet_thumbnails, function(x) x[["medium"]][["url"]]))
 
  }
  
  video_views = as.integer(video_views)
  videos = data.frame(playlist_title,video_id,video_title,video_published,video_views,video_thumbnail,video_url)
  
  # Apply column transformations  
  videos$video_year = as.integer( lubridate::year(videos$video_published) )
  videos$video_published = as.Date(videos$video_published)
  # Trim Video Title
  videos$video_title = gsub("\\s+", " ", videos$video_title)
  videos$video_title = trimws(videos$video_title)
  
  videos$video_days = as.integer( 1 + as.Date(Sys.Date()) - videos$video_published ) 
  videos$video_performance = round( videos$video_views / videos$video_days, 2) 
  
  return( videos )
}


MERGE_VIDEOS_WITH_CAPTIONS = function(videos,captions) {
  
  # full join videos with captions by video_id
  videos = dplyr::full_join(videos,captions, by = "video_id")
  
  #videos = videos |>
  #  dplyr::group_by(video_id) |>
  #  dplyr::filter(track_kind == max(track_kind)) |>
  #  dplyr::ungroup() |>
    # Caso existam duplicados absolutos (ex: dois 'standard' iguais), 
    # usamos o distinct para garantir unicidade por video_id
  #  dplyr::distinct(video_id, .keep_all = TRUE)
  
  # Added support for videos with no captions (track_kind is NA)
  videos = videos |>
    dplyr::group_by(video_id) |>
    dplyr::filter(
      if (all(is.na(track_kind))) TRUE
      else track_kind == max(track_kind, na.rm = TRUE)
    ) |>
    dplyr::ungroup() |>
    dplyr::distinct(video_id, .keep_all = TRUE)
  
  videos = subset(videos, select = c(playlist_title,
                                     video_id,
                                     video_title,
                                     video_published,
                                     video_views,
                                     video_thumbnail,
                                     video_url,
                                     video_year,
                                     caption_id,
                                     language,
                                     track_kind) )
 
  return(videos)
}


PLOT_BARPLOT_VIDEOS_BY_PLAYLIST = function() {
  # Neither ggplot2 nor normal barplot supports color emojis
  videos_by_playlist = data.frame(table(videos$playlist_title))
  names(videos_by_playlist) = c("playlist_title","Count")
  
  # But Plotly supports it !
  p = plotly::plot_ly(
    data = videos_by_playlist,
    x = ~reorder(playlist_title, Count), 
    y = ~Count,
    type = "bar",
    marker = list(color = 'orange', line = list(color = 'black', width = 1))
  ) |>
    plotly::layout(
      title = "Total Videos by Playlist",
      xaxis = list(title = "", tickangle = 315),
      yaxis = list(title = "Total"),
      margin = list(l = 50, r = 50, b = 50, t = 80) # Increases margins (in pixels)
    )
  
  # Display the plot
  p
}


PLOT_PIECHART_VIDEOS_BY_PLAYLIST = function() {
  # Neither ggplot2 nor normal barplot supports color emojis
  videos_by_playlist = data.frame(table(videos$playlist_title))
  names(videos_by_playlist) = c("playlist_title","Count")
  
  # Create the plotly pie chart
  p = plotly::plot_ly(
    data = videos_by_playlist,
    labels = ~playlist_title,  # Set the slice labels
    values = ~Count,           # Set the slice sizes
    type = "pie",
    marker = list(line = list(color = 'black', width = 1)) # Retains the black border
  ) |>
    plotly::layout(
      title = "Total Videos by Playlist",
      showlegend = TRUE,
      margin = list(l = 50, r = 50, b = 50, t = 80) # Increases margins (in pixels)
    )
  
  # Display the plot
  p
}


PROCESS_INFINIFACTORY_VIDEOS = function() {
  
  infinifactory = subset(videos, grepl("Infinifactory",playlist_title))
  # Convert Video Title to Title Case
  infinifactory$video_title = tools::toTitleCase(tolower(infinifactory$video_title))
  
  # Extract Number of Blocks from Infinifactory Videos
  infinifactory$Blocks = as.integer( sub(".*?(\\d+)\\s*Blocks.*", "\\1", infinifactory$video_title) )
  # Where Blocks !isNaN simplify the video title
  for ( i in 1:nrow(infinifactory) ) {
    blocks = infinifactory$Blocks[i]
    if ( !is.na(blocks) ) {
      N = nchar(as.character(blocks))
      L = nchar(infinifactory$video_title[i])
      infinifactory$video_title[i] = substring(infinifactory$video_title[i], 1, L - N - 9)
    } 
  }
  
  # Sort DataFrame
  infinifactory = infinifactory[order(infinifactory$video_title,-infinifactory$Blocks),]
  
  # Reset Row Numbers
  row.names(infinifactory) = NULL
  
  HTML = minifunctions::printdataframe(infinifactory)
  
  kableExtra::save_kable(HTML,file.path("infinifactory","infinifactory.html"))
  
}


SANITIZE_FILENAME = function(file_name) {
  
  # Caracteres proibidos no Windows:
  # < > : " / \ | ? *
  file_name = gsub('[<>:"/\\\\|?*]', " ", file_name)
  file_name = gsub("'", " ", file_name)
  
  # Remove caracteres de controlo invisíveis
  file_name = gsub("[[:cntrl:]]", " ", file_name)
  
  # Substitui múltiplos espaços por um só
  file_name = gsub("\\s+", " ", file_name)
  
  # Remove espaços no início e fim
  file_name = trimws(file_name)
  
  return(file_name)
}

