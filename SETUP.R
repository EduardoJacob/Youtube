

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


usethis::use_git_ignore("tools/")

usethis::use_git()

usethis::use_github()

usethis::use_readme_rmd()

usethis::browse_github()

rstudiotools::setcwd("./screenshots")
rstudiotools::displaymedia()
rstudiotools::setcwd()


# Start LM Studio if needed (if terminal already in use, close terminal panel and run again)
terminal_id = rstudiotools::terminal("./powershell/LMstudioStart.ps1",caption="Claude")
# Start Claude Code if needed
terminal_id = rstudiotools::terminal("claude --model qwen/qwen3.5-9b",terminal_id = terminal_id)

# prompt = "Review the project and update claude.md to reflect the current architecture and recent changes."
# terminal_id = rstudiotools::terminal(prompt, terminal_id = terminal_id)
terminal_id = rstudiotools::terminal("qual a capital de El Salvador ?", terminal_id = terminal_id)









