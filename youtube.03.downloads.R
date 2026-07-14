
# set snippet ----
# usethis::edit_rstudio_snippets()
# Ctrl+Shift-P - Show Command Palette
rstudiotools::setcwd()
try( dev.off(dev.list()["RStudioGD"]),silent=T) # Clear Plots
rm(list=ls()) # Clear Workspace
gc()
cat("\014") # Clear Console ctrl+L
xfunctions::XLibrary("geniusr")
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

minifunctions::imagegrid("P:/DISKD/Youtube R Programming/AppLogos")

source("youtubeFunctions.R")

# rstudiotools::displaymedia()

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
# minifunctions::printdataframe(TugaStone)
# minifunctions::imagegrid("P:/DISKD/Youtube R Programming/AppLogos")

download = DOWNLOAD_FROM_YOUTUBE_ASK_VALUES(MusicFolder = "C:/MEGA/Music")
# saveRDS(download,"download.rds")

DOWNLOAD_FROM_YOUTUBE_CREATE_FOLDER(download)

DOWNLOAD_FROM_YOUTUBE(download)

DOWNLOAD_FROM_YOUTUBE_MASS_RENAME(download)

# Open Explorer to check file names and optionally aply Mass Rename
shell.exec(download["OutputFolder",])

DOWNLOAD_FROM_YOUTUBE_INSERT_METADATA(download)

# Play sample music
mp3 = list.files(path=download["OutputFolder",],pattern = "\\.mp3$",full.names = TRUE,ignore.case = TRUE)
rstudiotools::displaymedia(mp3[1])


stop("Lyrics not working yet")


# Nao consegui pôr as Lyrics a funcionar. 
# Pelo menos, não aparecem no musicbee
# Apesar de elas serem inseridas na musica
# Apply Lyrics
OutputFolder = download["OutputFolder",]
mp3s = list.files(OutputFolder,pattern = "\\.mp3$",full.names = T)
lyrics = readRDS("JoannaNewsomLyrics.rds")

escape_ffmpeg = function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\"', x)
  x <- gsub("\n", "\\\\n", x)
  x
}

from_index = 28
to_index = 32
to_index = 28
N = to_index - from_index + 1
i = 1
for ( i in 1:N ) {
  Title = lyrics$Title[from_index + i - 1]
  Lyrics = lyrics$Lyrics[from_index + i - 1]
  mp3 = mp3s[i]
  
  cat("Apply Lyrics",i,"/",N,":",Title,"in mp3:",mp3,"\n")
  
  html = htmltools::tags$pre(
    style = "
      white-space: pre-wrap;
      font-family: sans-serif;
      font-size: 16px;
      padding: 20px;
  ",
   Lyrics
  )
  
  htmltools::browsable(html)
  
  # Insert Lyrics into mp3 metadata using ffmpeg
  # https://eyed3.readthedocs.io/en/v0.9.8/installation.html
  
  tmp = tempfile(fileext = ".mp3")
  
  # Using ffmpeg to add lyrics metadata
  cmd = sprintf(
    paste(
      'ffmpeg -y',
      '-i "%s"',
      '-map 0:a',
      '-c:a copy',
      '-id3v2_version 3',
      '-write_id3v1 1',
      '-metadata:s:v title=""',
      '-metadata:s:v comment=""',
      '-metadata lyrics="%s"',
      '"%s"'
    ),
    mp3,
    escape_ffmpeg(Lyrics),
    tmp
  )

  system(cmd)
  
  file.copy(tmp, mp3, overwrite = TRUE)
  unlink(tmp)
}


# To verify that the lyrics were added, you can use ffmpeg to read the metadata:
system(sprintf('ffprobe "%s"', mp3))
 

