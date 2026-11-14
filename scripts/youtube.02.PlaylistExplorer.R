
# Load Functions ----
source("youtubeFunctions.R")

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
minifunctions::printdataframe(TugaStone,expand_images = T)

# Select Playlist to Process ----
playlist = "PLSg3H9hyA_HU" # Matematica
playlist = "PLV2rd1meSZm0" # AI Productions
playlist = "PLRbCt61PaxX2d0_QXh6Qi6_jAQd66fmcI" # R Programming
playlist_title = GET_PLAYLIST_TITLE(playlist)

CREATE_SUBFOLDERS(playlist_title)

# Get Captions IDs ----
captions = GET_CAPTIONS_FROM_PLAYLIST(playlist)
videos = GET_VIDEOS_FROM_PLAYLISTS(data.frame(playlist_id=playlist, playlist_title=playlist_title))
videos = MERGE_VIDEOS_WITH_CAPTIONS(videos,captions)

# Download Thumbnails and Plot Thumbnails Grid ----
DOWNLOAD_THUMBNAILS(videos)

DOWNLOAD_CAPTIONS(videos)

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



