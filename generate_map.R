# Purpose: Generate interactive museum map with website links

if (!require("readxl", character.only = TRUE)) install.packages("readxl", repos = "http://cran.us.r-project.org")
if (!require("dplyr", character.only = TRUE)) install.packages("dplyr", repos = "http://cran.us.r-project.org")
if (!require("leaflet", character.only = TRUE)) install.packages("leaflet", repos = "http://cran.us.r-project.org")
if (!require("htmlwidgets", character.only = TRUE)) install.packages("htmlwidgets", repos = "http://cran.us.r-project.org")

library(readxl)
library(dplyr)
library(leaflet)
library(htmlwidgets)

# Set Pandoc path for self-contained HTML
Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")

# Read data
data_path <- "Marini_iDigBio_306museums_coord_with_country_for518Map.xlsx"
df <- read_excel(data_path)

# Data Cleaning & Popup Creation
df_clean <- df %>%
  mutate(
    # Round coordinates to 5 decimal places
    Latitude = round(Latitude, 5),
    Longitude = round(Longitude, 5),

    # Handle missing website links
    website_html = case_when(
      is.na(Website) | Website == "" ~ Museum,
      TRUE ~ paste0("<a href='", Website, "' target='_blank'>", Museum, "</a>")
    ),

    # Construct popup text
    popup_text = paste0(
      "<b>博物館:</b> ", website_html, "<br>",
      "<b>地點:</b> ", Country, "<br>",
      "<b>蛋標本組數:</b> ", format(round(as.numeric(egg_sets_estimated)), big.mark = ",", scientific = FALSE, trim = TRUE)
    )
  )

# Generate Leaflet Map
m <- leaflet(df_clean) %>%
  addTiles(urlTemplate = "https://mt1.google.com/vt/lyrs=m&hl=zh-TW&x={x}&y={y}&z={z}") %>%
  addMarkers(
    lng = ~Longitude,
    lat = ~Latitude,
    popup = ~popup_text,
    clusterOptions = markerClusterOptions()
  ) %>%
  addControl(
    html = htmltools::HTML("<div style='background: rgba(255, 255, 255, 0.8); font-size: 30px; font-weight: bold; padding: 20px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); line-height: 1.2;'>全球鳥蛋博物館地圖</div>"),
    position = "bottomleft",
    className = ""
  )

# Save self-contained HTML
saveWidget(m, file = "index.html", selfcontained = TRUE)

# Workaround for Pandoc 3.0+ bug that incorrectly wraps htmlwidgets with {=html}
html_content <- readLines("index.html", warn = FALSE, encoding = "UTF-8")
if (any(grepl("\\{=html\\}", html_content))) {
  html_content <- gsub("<p><code>\\{=html\\}\\s*", "", html_content)
  html_content <- gsub("</div>\\s*</code></p>", "</div>", html_content)
  writeLines(html_content, "index.html", useBytes = TRUE)
}

cat("Map generated successfully and saved to index.html\n")
