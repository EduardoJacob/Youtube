
# set snippet ----
# usethis::edit_rstudio_snippets()
# Ctrl+Shift-P - Show Command Palette
rstudiotools::setcwd()
try( dev.off(dev.list()["RStudioGD"]),silent=T) # Clear Plots
rm(list=ls()) # Clear Workspace
gc()
cat("\014") # Clear Console ctrl+L
xfunctions::XLibrary("fs","zeallot","svDialogs","geniusr")
# xfunctions::XFunctions("fs")
help(package="geniusr")
# packageDescription("fs")
# devtools::install_github("author_name/fs", build_vignettes = TRUE, dependencies = TRUE)
# browseVignettes(package="fs")
# vignette(package="fs")
# vignette("vignette-name",package="fs")
# https://cranlogs.r-pkg.org/badges/last-month/fs
rstudiotools::showinfo()

# download https://github.com/yt-dlp/yt-dlp to download the videos in the playlist
# download deno.exe from https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip

source("youtubeFunctions.R")

# rstudiotools::displaymedia()

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
# minifunctions::printdataframe(TugaStone)
# minifunctions::imagegrid("P:/DISKD/Youtube R Programming/AppLogos")

download = DOWNLOAD_FROM_YOUTUBE_ASK_VALUES(MusicFolder = "C:/MEGA/Music")

DOWNLOAD_FROM_YOUTUBE_CREATE_FOLDER(download)

DOWNLOAD_FROM_YOUTUBE(download)

# Open Explorer to check file names
# shell.exec(download["OutputFolder",])

DOWNLOAD_FROM_YOUTUBE_MASS_RENAME(download)

DOWNLOAD_FROM_YOUTUBE_INSERT_COVER(download)


# https://genius.com/api-clients
# Artist = "Jon and Vangelis"
# OutputFolder = "C:/MEGA/Music/Jon & Vangelis - The Friends Of Mr. Cairo"
# track_name = "The Friends Of Mr. Cairo"
# mp3s = list.files(OutputFolder,pattern = "\\.mp3$",full.names = FALSE)

# 2. Search for the song on Genius to find its internal ID
# search_results = geniusr::search_song(search_term = paste(Artist, track_name),n_results=1)

# 3. Take the first match (most relevant) and extract its Genius ID
# best_match_id = search_results$song_id[1]

# 4. Fetch the lyrics using that ID
# lyrics_dataframe = geniusr::get_lyrics_id(song_id = best_match_id)

# 5. View the lyrics
# The output is a clean tibble/dataframe with line-by-line text
# head(lyrics_dataframe)









