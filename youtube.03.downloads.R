
# set snippet ----
# usethis::edit_rstudio_snippets()
# Ctrl+Shift-P - Show Command Palette
rstudiotools::setcwd()
try( dev.off(dev.list()["RStudioGD"]),silent=T) # Clear Plots
rm(list=ls()) # Clear Workspace
gc()
cat("\014") # Clear Console ctrl+L
xfunctions::XLibrary("fs","zeallot","svDialogs","notifier")
# xfunctions::XFunctions("fs")
help(package="notifier")
packageDescription("fs")
# devtools::install_github("author_name/fs", build_vignettes = TRUE, dependencies = TRUE)
# browseVignettes(package="fs")
# vignette(package="fs")
# vignette("vignette-name",package="fs")
# https://cranlogs.r-pkg.org/badges/last-month/fs
rstudiotools::showinfo()

# pak::pak("gaborcsardi/notifier") fails
# remotes::install_github("gaborcsardi/notifier") fails
# remotes::install_github("r-lib/notifier") fails
# install.packages("https://cran.r-project.org/src/contrib/Archive/notifier/notifier_1.0.0.tar.gz") success

source("youtubeFunctions.R")

# rstudiotools::displaymedia()

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
# minifunctions::printdataframe(TugaStone)
minifunctions::imagegrid("P:/DISKD/Youtube R Programming/AppLogos")

MusicFolder = "C:/MEGA/Music"

# Find full Albums at https://music.youtube.com/
# youtube_url = "https://www.youtube.com/playlist?list=OLAK5uy_lOq4NjXU5q4EN0BTR67iTW7e_g_3qa5jc"
youtube_url = trimws( svDialogs::dlgInput("YouTube URL?", default = "")$res )
youtube_url = sub("&.*", "", youtube_url)

# destructuring assignment with package zeallot
c(url_type, AlbumArtist, Album, Cover) %<-% GET_METADATA_FROM_YOUTUBE_URL(youtube_url)

# Create OutputFolder
AlbumFolder = paste0(AlbumArtist," - ",Album)
AlbumFolder = SANITIZE_FILENAME(AlbumFolder)
OutputFolder = paste0(MusicFolder,"/",AlbumFolder)
fs::dir_create(OutputFolder)

# Save Cover
filename = paste0(OutputFolder,"/00.jpg")
utils::download.file(url=Cover,destfile=filename,mode = "wb")

# Save youtube_url
filename = paste0(OutputFolder,"/",AlbumFolder,".txt")
writeLines(youtube_url,filename)
 

# download https://github.com/yt-dlp/yt-dlp to download the videos in the playlist
# download deno.exe from https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip

command = GET_YT_DLP_COMMAND(youtube_url,OutputFolder,url_type)
terminal_id = rstudiotools::terminal(command, caption="YT_DLP")
# notifier::notify(title="Download started",msg="")


# Mass rename 
prefix = paste0(AlbumFolder," - ")
command = paste0("Get-ChildItem '",OutputFolder,"/*' | ")
command = paste0(command,"Where-Object { $_.BaseName -match '^\\d{2}' } | ")
command = paste0(command,"Rename-Item -NewName { '",prefix,"' + $_.Name }")
terminal_id = rstudiotools::terminal(command,terminal_id = terminal_id)

# Open Explorer to check file names
shell.exec(OutputFolder)

# Call mp3tag
full_path = normalizePath(OutputFolder, mustWork = TRUE)
rc = system2("C:/Program Files/Mp3tag/Mp3tag.exe", args = c(paste0("/fp:", shQuote(full_path))))



