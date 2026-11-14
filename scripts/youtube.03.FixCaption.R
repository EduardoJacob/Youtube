
# Load Functions ----
source("youtubeFunctions.R")

# Access my profile ----
TugaStone = AUTHENTICATE_TUBER()

caption_id = "AUieDabivTQzYC_hwQsPC1m0RQnea9vnDhIgKarNPcf9HeXNZRE"

captions = tuber::download_caption(
  caption_id = caption_id, lang = "pt", format = "sbv", as_raw = F
)

# Edit and fix the captions



