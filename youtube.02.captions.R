

source("youtubeFunctions.R")

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()
minifunctions::printdataframe(TugaStone)


# Get Captions ----
# Get playlist_id from playlists dataframe where playlist_title is "R Programming"
# rprogramming_playlist = playlists$playlist_id[playlists$playlist_title == "R Programming"]
rprogramming_playlist = "PLRbCt61PaxX2d0_QXh6Qi6_jAQd66fmcI"
rprogramming_captions = GET_CAPTIONS_FROM_PLAYLIST(rprogramming_playlist)
rprogramming = GET_VIDEOS_FROM_PLAYLISTS(data.frame(playlist_id=rprogramming_playlist, playlist_title="R Programming"))
rprogramming = MERGE_VIDEOS_WITH_CAPTIONS(rprogramming, rprogramming_captions)
PLOT_THUMBNAILS(rprogramming$video_thumbnail,ncol=5,nrow=5)
# EVOLUTION_OF_PLAYLIST_VIEWS(rprogramming_playlist) IS NOT WORKING 

# pixaroma_playlist = "PL-pohOSaL8P-FhSw1Iwf0pBGzXdtv4DZC"
# pixaroma_captions = GET_CAPTIONS_FROM_PLAYLIST(pixaroma_playlist)
# pixaroma = GET_VIDEOS_FROM_PLAYLISTS(data.frame(playlist_id=pixaroma_playlist, playlist_title="Pixaroma"))
# pixaroma = MERGE_VIDEOS_WITH_CAPTIONS(pixaroma, pixaroma_captions)
# PLOT_THUMBNAILS(pixaroma$video_thumbnail,ncol=4,nrow=4)

captions = GET_CAPTIONS(rprogramming)

prompt = "Give me the main topics of the following text in portuguese, with no more than 10 topics and no title. Format the result as a numbered list "
N = length(captions)

# Make sure LM Studio starts
system2("powershell", args = c("-File", paste0('./powershell/LMstudioStart.ps1')), stdout = T, stderr = F, wait = T) 


# Get topics from captions using AI: 
# LM Studio load Qwen3.5 9B context length 100000 tokens - 10.68GB
# answer = aitools::lmstudio("What is your formal model name and version?") 
# model_name = stringr::str_extract(answer, "(?<=\\*\\*).*?(?=\\*\\*)")
Qwen = vector()
QwenElapsedTime = system.time( for (i in 1:N) Qwen = c(Qwen, aitools::lmstudio(paste(prompt, captions[i])))  )[3]

# LM Studio load Gemma 4 26B context length 100000 tokens - 24.44GB
# Gemma = vector()
# for (i in 1:N) Gemma = c(Gemma, aitools::lmstudio(paste(prompt, captions[i])))

# answer = aitools::gemini("What is your formal model name and version?") 
# Gemini = vector()
# GeminiElapsedTime = system.time( for (i in 1:N) Gemini = c(Gemini, aitools::gemini(paste(prompt, captions[i]))) )[3]

# Report = data.frame(Video = df$video_thumbnail[1:N], Qwen3.5 = Qwen, Gemini2.5flash = Gemini, Gemma4 = Gemma) 
# Report = data.frame(Video = rprogramming$video_thumbnail[1:N], Qwen3.5 = Qwen, Gemini2.5flash = Gemini) 
Report = data.frame(Video = rprogramming$video_thumbnail[1:N], Qwen3.5 = Qwen) 

minifunctions::printdataframe(Report,expand_images = T)









