

AUTHENTICATE_TUBER = function() { 
  # Autentication — uses Client ID, Client Secret from Google Cloud
  # https://console.cloud.google.com/auth/clients?project=chromeextension-1606581122438
  YOUTUBE_CLIENT_ID = Sys.getenv("YOUTUBE_CLIENT_ID")
  YOUTUBE_CLIENT_SECRET = Sys.getenv("YOUTUBE_CLIENT_SECRET")
  setwd("./tuber_oauth")
  tuber::yt_oauth(YOUTUBE_CLIENT_ID,YOUTUBE_CLIENT_SECRET)
  setwd("..")
  
  YOUTUBE_CHANNEL_ID = Sys.getenv("YOUTUBE_CHANNEL_ID")
  stats = tuber::get_channel_stats(channel_ids=YOUTUBE_CHANNEL_ID)
  
  profile = c(Title       = stats$title,
              Description = stats$description,
              ChannelID   = stats$channel_id,
              Handle      = stats$custom_url,
              URL         = paste0("https://www.youtube.com/",stats$custom_url),
              Joined      = as.character( as.Date(stats$published_at) ),
              CountryCode = stats$country,
              Country     = countrycode::countrycode(stats$country, "iso2c", "country.name") ,
              Views       = stats$view_count,
              Subscribers = stats$subscriber_count,
              Videos      = stats$video_count,
              Avatar      = stats$thumbnail_url)
  
  profile = data.frame(profile=profile)
  
  # avatarfull = imager::load.image(Avatar) It fails
  avatarfull = magick::image_read(profile["Avatar",])
  # avatarfull = magick::image_annotate(avatarfull, Title, 
  #                                 size = 30,         # Font size
  #                                 gravity = "north", # Position (top center)
  #                                 color = "black",   # Text color
  #                                 location = "+0+10") # Small offset from the top
  plot(avatarfull)
  
  return(profile)
}


AUTHENTICATE_YTANALYTICS = function() {
  # file remove is now mandatory since we are working with 2 different packages that use the same .httr-oauth file.
  # file.remove(".httr-oauth")
  YOUTUBE_CLIENT_ID = Sys.getenv("YOUTUBE_CLIENT_ID")
  YOUTUBE_CLIENT_SECRET = Sys.getenv("YOUTUBE_CLIENT_SECRET")
  setwd("./ytanalytics_oauth")
  token = YTAnalytics::youtube_oauth(clientId = YOUTUBE_CLIENT_ID, clientSecret = YOUTUBE_CLIENT_SECRET)
  setwd("..")
  return(token) 
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
  
  Uploads = Uploads %>%
    count(Date, name = "uploads") %>%      
    arrange(Date) %>%
    mutate(cumulative_uploads = cumsum(uploads))
  
  Uploads$uploads = NULL
  
  # Filter fromDate
  Views = Views[Views$Date >= fromDate, ]
  Uploads = Uploads[Uploads$Date >= fromDate, ]
  
  # PLOTLY DUAL AXIS 
  
  p = plotly::plot_ly() %>%
    
    # LEFT Y AXIS - cumulative views
    plotly::add_lines(
      data = Views,
      x = ~Date,
      y = ~cumulative_views,
      name = "Cumulative Views",
      yaxis ="y",
      line = list(width = 3)
    ) %>%
    
    # RIGHT Y AXIS - cumulative uploads
    plotly::add_lines(
      data = Uploads,
      x = ~Date,
      y = ~cumulative_uploads,
      name = "Cumulative Uploads",
      yaxis = "y2",
      line = list(width = 3)
    ) %>%
    
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
    playlistId = playlist,token = token,
    metrics = "views",
    dimensions = "day",            
    startDate = "2026-04-01",     
    endDate = as.character(Sys.Date()),
    sort = "day",
    maxResults = 10000
  )
  
}


GET_CAPTIONS = function(df) {
  N = nrow(df)
  CaptionsVector = vector()
  for (i in 1:N) {
    cat("Processing video", i, "of", N, "\n")
    captions = tuber::get_captions(id = df$caption_id[i],lang=df$language[i],format="sbv",as_raw=F)
    captions = data.frame(captions)
    
    # Extract text from captions, removing timestamps and empty lines
    captions = captions %>%
      dplyr::pull(captions) %>%
      .[!stringr::str_detect(., "[0-9]:[0-9]{2}:[0-9]{2}")] %>%
      .[. != "" & !is.na(.)] %>%
      stringr::str_c(collapse = " ")
    
    captions = stringr::str_squish(captions)
    
    CaptionsVector = c(CaptionsVector, captions)
  }
  
  return(CaptionsVector)
}


GET_CAPTIONS_FROM_PLAYLIST = function(playlist_id) {
  suppressMessages({
    playlist_videos = tuber::get_playlist_items(filter =c(playlist_id = playlist_id),max_results = 500)
  })
  # Create empty dataframe to store captions
  # asr stands for Automatic Speech Recognition
  captions = data.frame()
  for (i in 1:nrow(playlist_videos)) {
    cat(".")
    df = tuber::list_caption_tracks(video_id = playlist_videos$contentDetails.videoId[i])
    captions = rbind(captions,df )
  } 
  cat(" ",nrow(playlist_videos),"videos,",nrow(captions),"captions") 
  cat("\n")
  
  # Rename column in captions from "videoId" to "video_id"
  names(captions)[names(captions) == "videoId"] = "video_id"
  
  return(captions)
}


GET_CHANNEL_PLAYLISTS = function(channel_id,exclude_playlists) {
  playlists = tuber::get_playlists(filter=c(channel_id=channel_id),max_results = 500) 
  
  playlist_id = vector()
  playlist_title = vector()
  for ( playlist in playlists$items) {
    playlist_id = c(playlist_id,playlist$id)
    playlist_title = c(playlist_title,playlist$snippet$title)
  }
  playlists = data.frame(playlist_id,playlist_title)
  
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
  video_id = videos$contentDetails.videoId
  return( data.frame(video_id))
}


GET_METADATA_FROM_YOUTUBE_URL = function(youtube_url) {
  # if youtube_url contains "playlist?list="
  if (grepl("playlist?list=", youtube_url, fixed = TRUE)) {
    id = strsplit(youtube_url,"list=")[[1]][2]
    details = tuber::get_playlists(filter=c(playlist_id=id)) 
    
    Album = details[["items"]][[1]][["snippet"]][["title"]]
    Cover = details[["items"]][[1]][["snippet"]][["thumbnails"]][["standard"]][["url"]]
    
    Channel = details[["items"]][[1]][["snippet"]][["channelTitle"]]
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
    if ( str_count(desc, "\\d{1,2}:\\d{2}") >= 3 ) url_type = "video_with_chapters"
  }
  
  cat( cli::rule(left = url_type, col = "blue"),"\n" )
  
  img = magick::image_read(Cover) 
  # print(img) - In the Viewer Pane - doesn't scale
  plot(img) # In the Plot pane - scales better
  
  AlbumArtist = trimws( svDialogs::dlgInput("Album Artist?", default = Channel)$res )
  Album = trimws( svDialogs::dlgInput("Album Name?", default = Album)$res )
   
  return(list(url_type,AlbumArtist,Album,Cover))
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
      playlist_videos = tuber::get_playlist_items(filter =c(playlist_id = playlists$playlist_id[i]),max_results = 500)
    })
    
    for ( id in playlist_videos$contentDetails.videoId ) {
      cat(".")
      playlist_title = c(playlist_title,playlistTitle)
      video_id = c(video_id,id)
      url = paste0("https://www.youtube.com/watch?v=",id)
      video_url = c(video_url,url)
      
      suppressMessages({
        video_detail = tuber::get_video_details(video_id = id)
        video_stats = tuber::get_stats(video_id = id)
      })
      
      video_title = c(video_title,video_detail$snippet_title)
      video_published = c(video_published,video_detail$snippet_publishedAt)
      video_views = c(video_views,video_stats$statistics_viewCount)
      video_thumbnail = c(video_thumbnail,video_detail$snippet_thumbnails[[1]][["medium"]][["url"]])
    }
    
    cat(" ",length(playlist_videos$contentDetails.videoId),"videos") 
    cat("\n")
     
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


GET_YT_DLP_COMMAND = function(youtube_url,OutputFolder,url_type) {
  
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
    command = "./tools/yt-dlp.exe --extract-audio "
    command = paste0(command,"--audio-format mp3 --audio-quality 0 ")
    command = paste0(command,"-P '",OutputFolder,"' ")
    command = paste0(command,"-o '%(title)s.%(ext)s' '")
    command = paste0(command,youtube_url,"'")
  }
  return(command)
}


MERGE_VIDEOS_WITH_CAPTIONS = function(videos,captions) {
  
  # full join videos with captions by video_id
  videos = dplyr::full_join(videos,captions, by = "video_id")
  
  videos = videos %>%
    dplyr::group_by(video_id) %>%
    dplyr::filter(trackKind == max(trackKind)) %>%
    dplyr::ungroup() %>%
    # Caso existam duplicados absolutos (ex: dois 'standard' iguais), 
    # usamos o distinct para garantir unicidade por video_id
    dplyr::distinct(video_id, .keep_all = TRUE)
  
  videos = subset(videos, select = c(playlist_title,
                                     video_id,
                                     video_title,
                                     video_published,
                                     video_views,
                                     video_thumbnail,
                                     video_url,
                                     video_year,
                                     id,
                                     language,
                                     trackKind) )
  # Rename column in videos from "id" to "caption_id"
  names(videos)[names(videos) == "id"] = "caption_id"
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
  ) %>%
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
  ) %>%
    plotly::layout(
      title = "Total Videos by Playlist",
      showlegend = TRUE,
      margin = list(l = 50, r = 50, b = 50, t = 80) # Increases margins (in pixels)
    )
  
  # Display the plot
  p
}


PLOT_THUMBNAILS = function(urls, ncol, nrow) {
  # i have an r vector with jpg urls. 
  # make me a function to download all the images and plot them in the plot pane or viewer pane in grid layout. 
  # the function must have 2 parameters: (number_of_columns,number_of_rows)
  # Create a temporary directory to store the downloaded images
  temp_dir = tempdir()
  file_paths = vector()
  
  # Download each image and store the file paths
  for ( i in 1:length(urls) ) {
    url = urls[i]
    file_name = basename(url)
    # split file_name into name and extension
    name = tools::file_path_sans_ext(file_name)
    ext = tools::file_ext(file_name)
    # create a new file name with the index
    file_name = paste0(name, "_", i, ".", ext)
    
    file_path = file.path(temp_dir, file_name)
    download.file(url, file_path, mode = "wb")
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
  
  kableExtra::save_kable(HTML,"infinifactory.html")
  
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

