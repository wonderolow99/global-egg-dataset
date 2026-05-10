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
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")

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
      "<b>Museum:</b> ", website_html, "<br>",
      "<b>Country:</b> ", Country, "<br>",
      "<b>Estimated Egg Sets:</b> ", egg_sets_estimated
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
  )

# Save self-contained HTML
saveWidget(m, file = "index.html", selfcontained = TRUE)

cat("Map generated successfully and saved to index.html\n")
