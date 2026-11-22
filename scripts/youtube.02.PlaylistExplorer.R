
# Load Functions ----
source("youtubeFunctions.R")

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
minifunctions::printdataframe(TugaStone,expand_images = T)

# Select Playlist to Process ---- 
playlist = "PLSg3H9hyA_HU" # Matematica
playlist = "PLFnYrWTRU6bg" # Explain
playlist = "PLRbCt61PaxX2d0_QXh6Qi6_jAQd66fmcI" # R Programming
playlist_title = GET_PLAYLIST_TITLE(playlist)

CREATE_SUBFOLDERS(playlist_title)

# Get Captions IDs ----
captions = GET_CAPTIONS_FROM_PLAYLIST(playlist)
videos = GET_VIDEOS_FROM_PLAYLISTS(data.frame(playlist_id=playlist, playlist_title=playlist_title))
videos = MERGE_VIDEOS_WITH_CAPTIONS(videos,captions)

# Download Thumbnails and Plot Thumbnails Grid ----
# It fails when video titles have special characters
# to circumvent this, we can use the video_id instead of the video_title to name the thumbnail files
MY_VIDEOS = F

if ( MY_VIDEOS ) {
  DOWNLOAD_THUMBNAILS(videos,use_video_titles = TRUE)
  # We can only download captions for videos we own, not from other people's videos. 
  DOWNLOAD_CAPTIONS(videos,timestamps = T,use_video_titles = TRUE)
} else {
  DOWNLOAD_THUMBNAILS(videos,use_video_titles = FALSE)
  DOWNLOAD_CAPTIONS_WITH_YT_DLP(videos,timestamps = F,use_video_titles = FALSE)
}




# Start LM Studio ----
terminal_list = rstudioapi::terminalList()
for (terminal_id in terminal_list) rstudioapi::terminalKill(terminal_id)
terminal_id = rstudiotools::terminal("./powershell/LMstudioStart.ps1",caption="LMstudio")

DOWNLOAD_SUMMARIES_FROM_LMSTUDIO(videos)


# html_file = paste0("./youtube_summaries/",playlist_title,".html")
 
 

# Print Video Summaries all at once ----
# N = nrow(summaries)
# Report = data.frame(Video = videos$video_thumbnail[1:N], Summary = summaries$summary, stringsAsFactors = F) 
# html = minifunctions::printdataframe(Report,expand_images = T)
# writeLines(html,html_file)



