

# f = xfunctions::XLibrary

# Install my packages from GitHub
# devtools::install_github("eduardojacob/xfunctions")
# devtools::install_github("eduardojacob/minifunctions")
# or alternatively:
# remotes::install_github("eduardojacob/xfunctions")
# pak::pak("eduardojacob/xfunctions")

# YouTube Data API v3: https://developers.google.com/youtube/v3 ( package tuber )
# YouTube Reporting API v1: https://developers.google.com/youtube/reporting/v1/reports/
# YouTube Analytics API v2: https://developers.google.com/youtube/analytics/explorer ( package YTAnalytics )

# You must define your YouTube API credentials in order to use the tuber and YTAnalytics packages. 
# You can do this by setting environment variables in your .Renviron file 
# usethis::edit_r_environ()
# YOUTUBE_USER_ID = "..."
# YOUTUBE_CHANNEL_ID = "..."
# YOUTUBE_CLIENT_ID = "..."
# YOUTUBE_CLIENT_SECRET = "..."

# Alternative:
# Read API credentials from Windows Credential Manager
# keyring::key_set("YOUTUBE_CHANNEL_ID")
# YOUTUBE_CHANNEL_ID = keyring::key_get("YOUTUBE_CHANNEL_ID")

# YOUTUBE_CHANNEL_ID = as.character( keys["YOUTUBE_CHANNEL_ID", , drop = TRUE] )
# YOUTUBE_CHANNEL_ID = Sys.getenv("YOUTUBE_CHANNEL_ID")

# my_channel = paste0("https://www.youtube.com/channel/",YOUTUBE_CHANNEL_ID)
# utils::browseURL(my_channel)
# YOUTUBE_HANDLE = "@tugastone"
# my_channel_alternate = paste0("https://www.youtube.com/",YOUTUBE_HANDLE)
# utils::browseURL(my_channel)

source("youtubeFunctions.R")
rstudiotools::showinfo()

# rstudiotools::displaymedia()

YOUTUBE_CHANNEL_ID = Sys.getenv("YOUTUBE_CHANNEL_ID")

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
minifunctions::printdataframe(TugaStone,expand_images = TRUE)

channel = tuber::analyze_channel(
  YOUTUBE_CHANNEL_ID,
  max_videos = 300,
  include_comments = FALSE
)
videos = channel$recent_videos

# List Subscribers
# subscribers = tuber::list_subscriptions(channel_id = YOUTUBE_CHANNEL_ID)

# Access all my videos (BUG) ----
# all_videos = GET_CHANNEL_VIDEOS(YOUTUBE_CHANNEL_ID)
# Check for duplicates - there's a bug in the API that sometimes returns duplicated videos, and also missing videos
# all_videos[duplicated(all_videos$video_id),]
# length(unique(all_videos$video_id))



# Access my Playlists ----
playlists = GET_CHANNEL_PLAYLISTS(YOUTUBE_CHANNEL_ID,exclude_playlists = c("Family","Music"))
videos = GET_VIDEOS_FROM_PLAYLISTS(playlists)
# List duplicated: videos in more than one playlist
videos[duplicated(videos$video_id),]
total_views = sum(videos$video_views)



# Number of Videos by Playlist ----
# minifunctions::tableprop(videos$playlist_title)
playlists$playlist_count = as.integer( table(videos$playlist_title) )
minifunctions::printdataframe(playlists)


# Generate Plots ----
PLOT_BARPLOT_VIDEOS_BY_PLAYLIST()

PLOT_PIECHART_VIDEOS_BY_PLAYLIST()

# List my total uploads by year ----
minifunctions::tableprop(videos$video_year)


# Statistics by playlist ----
playlist_summary <- videos |>
  dplyr::group_by(playlist_title) |>
  dplyr::summarise(
    total_videos = dplyr::n(),
    total_views = sum(video_views, na.rm = TRUE),
    average_views = mean(video_views, na.rm = TRUE),
    min_video_published = min(video_published, na.rm = TRUE),
    max_video_published = max(video_published, na.rm = TRUE),
    # Calculate elapsed days
    # elapsed_days = 1 + as.numeric(difftime(max_video_published, min_video_published, units = "days"))
    elapsed_days = as.numeric(difftime(Sys.Date(), min_video_published, units = "days"))
 ) |>
  dplyr::ungroup()

# playlist_summary order by average_views
playlist_summary <- playlist_summary |>
  dplyr::arrange(dplyr::desc(average_views))

minifunctions::printdataframe(playlist_summary)


# Barplot Uploads per year and Playlist
library(dplyr)
library(plotly)
library(scales)

df <- videos %>%
  count(video_year, playlist_title, name = "total") %>%
  mutate(
    label = substr(playlist_title, 1, 1)
  )

plot_ly(
  df,
  x = ~video_year,
  y = ~total,
  color = ~playlist_title,
  colors = hue_pal()(n_distinct(df$playlist_title)),
  type = "bar",
  text = ~label,
  textposition = "inside",
  insidetextanchor = "middle",
  textfont = list(color = "white",size = 50)
) %>%
  layout(
    title = list(
      text = "Number of videos by year and playlist",
      font = list(size = 40,weight = "bold"),
      x = 0.5,
      y = 0.96,
      xanchor = "center"
    ),
    barmode = "stack",
    xaxis = list(
      title = list(
        text = "Year",
        font = list(size = 25)
      ),
      tickfont = list(size = 25)
    ),
    
    yaxis = list(
      title = list(
        text = "Number of videos",
        font = list(size = 25)
      ),
      tickfont = list(size = 25)
    ),
    legend = list(
      x = 0,
      y = 0.94,
      xanchor = "left",
      yanchor = "top",
      bgcolor = "rgba(255,255,255,0.7)",
      font = list(size = 25)
    )
  )



 
# Process Infinifactory Videos ----
PROCESS_INFINIFACTORY_VIDEOS()

# Evolution of my Views over time ----
EVOLUTION_OF_MY_VIEWS(fromDate="2025-11-01")


# subscriptions = tuber::list_subscriptions(my_subscribers=T)






