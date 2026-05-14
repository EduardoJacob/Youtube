
# set snippet ----
# usethis::edit_rstudio_snippets()
# Ctrl+Shift-P - Show Command Palette
rstudiotools::setcwd()
try( dev.off(dev.list()["RStudioGD"]),silent=T) # Clear Plots
rm(list=ls()) # Clear Workspace
gc()
cat("\014") # Clear Console ctrl+L
xfunctions::XLibrary("xfunctions")
# xfunctions::XFunctions("xfunctions")
help(package="xfunctions")
packageDescription("xfunctions")
# devtools::install_github("author_name/xfunctions", build_vignettes = TRUE, dependencies = TRUE)
# browseVignettes(package="xfunctions")
# vignette(package="xfunctions")
# vignette("vignette-name",package="xfunctions")
# https://cranlogs.r-pkg.org/badges/last-month/xfunctions
rstudiotools::showinfo()

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

# rstudiotools::displaymedia()

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
minifunctions::printdataframe(TugaStone)

YOUTUBE_CHANNEL_ID = Sys.getenv("YOUTUBE_CHANNEL_ID")

# Access all my videos (BUG) ----
all_videos = GET_CHANNEL_VIDEOS(YOUTUBE_CHANNEL_ID)
# Check for duplicates - there's a bug in the API that sometimes returns duplicated videos, and also missing videos
all_videos[duplicated(all_videos$video_id),]
length(unique(all_videos$video_id))



# Access my Playlists ----
playlists = GET_CHANNEL_PLAYLISTS(YOUTUBE_CHANNEL_ID,exclude_playlists = c("Family","Music"))
videos = GET_VIDEOS_FROM_PLAYLISTS(playlists)
# List duplicated: videos in more than one playlist
videos[duplicated(videos$video_id),]
total_views = sum(videos$video_views)


# Check Missing or Orphan Videos ----
# Orphan all_videos not on videos
dplyr::anti_join(all_videos,videos,by = "video_id")
# Orphan videos not on all_videos
dplyr::anti_join(videos,all_videos,by = "video_id")
# remove all_videos dataframe (there's a bug on the API which originates duplicates and missing videos)
rm(all_videos)



# Number of Videos by Playlist ----
minifunctions::tableprop(videos$playlist_title)


# Generate Plots ----
PLOT_BARPLOT_VIDEOS_BY_PLAYLIST()

PLOT_PIECHART_VIDEOS_BY_PLAYLIST()


# List my total uploads by year ----
minifunctions::tableprop(videos$video_year)


# Statistics by playlist ----
playlist_summary <- videos %>%
  dplyr::group_by(playlist_title) %>%
  dplyr::summarise(
    total_videos = dplyr::n(),
    total_views = sum(video_views, na.rm = TRUE),
    average_views = mean(video_views, na.rm = TRUE),
    min_video_published = min(video_published, na.rm = TRUE),
    max_video_published = max(video_published, na.rm = TRUE),
    # Calculate elapsed days
    # elapsed_days = 1 + as.numeric(difftime(max_video_published, min_video_published, units = "days"))
    elapsed_days = as.numeric(difftime(Sys.Date(), min_video_published, units = "days"))
 ) %>%
  dplyr::ungroup()

# playlist_summary order by average_views
playlist_summary <- playlist_summary %>%
  dplyr::arrange(dplyr::desc(average_views))

minifunctions::printdataframe(playlist_summary)


 
# Process Infinifactory Videos ----
PROCESS_INFINIFACTORY_VIDEOS()

# Evolution of my Views over time ----
EVOLUTION_OF_MY_VIEWS(fromDate="2025-11-01")








