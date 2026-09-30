# Export the app data to csv files for the static site (openpisaStatic)
# Run after pisaScoresMerge.R, analyzeData2025.R and israel2025.R
library(tidyverse)

appData <- "C:/Users/Avner/OneDrive/R/pisa/openpisa5Hebrew/data/"
staticData <- "C:/Users/Avner/OneDrive/R/pisa/openpisaStatic/data/"

load(paste0(appData, "pisaScores.rda"))
load(paste0(appData, "analyzeData2025.rda"))
load(paste0(appData, "israel2025.rda"))
countries <- read_csv(paste0(appData, "countries.csv"), show_col_types = FALSE)

# same join as server.R: only countries with a Hebrew name are shown
scores <- pisaScores %>%
  filter(Subject %in% c("Math", "Science", "Reading"), !is.na(Average)) %>%
  inner_join(countries %>% select(Country, Hebrew), by = "Country") %>%
  transmute(Year, Country = Hebrew, Subject, Gender, ESCS, GenderESCS, Average = round(Average, 1)) %>%
  arrange(Country, Subject, GenderESCS, Year)

write_csv(scores, paste0(staticData, "scores.csv"))
# English page: all countries with current OECD names, no join with countries.csv
# The Israeli sector groups are left out, as on the Hebrew page (no 2022 data for them)
currentNames <- c(
  "United States of America" = "United States",
  "Hong Kong-China" = "Hong Kong (China)",
  "Macao-China" = "Macao (China)",
  "Turkey" = "Türkiye",
  "Czech Republic" = "Czechia",
  "Macedonia" = "North Macedonia",
  "Moldova" = "Republic of Moldova",
  "Viet Nam" = "Vietnam"
)
scoresEn <- pisaScores %>%
  filter(Subject %in% c("Math", "Science", "Reading"), !is.na(Average),
         !Country %in% c("Arabic Secular", "Israel Hebrew", "Israel Arabic", "Israel Hebrew Secular",
                         "Israel Hebrew Religious", "Israel Ultra Orthodox Girls")) %>%
  mutate(Country = ifelse(Country %in% names(currentNames), currentNames[Country], Country)) %>%
  transmute(Year, Country, Subject, Gender, ESCS, GenderESCS, Average = round(Average, 1)) %>%
  arrange(Country, Subject, GenderESCS, Year)
write_csv(scoresEn, paste0(staticData, "scores_en.csv"))

write_csv(analyzeData, paste0(staticData, "analyze.csv"))
write_csv(israel2025 %>% mutate(across(where(is.double), ~ round(., 4))), paste0(staticData, "pisa_israel_2025.csv"), na = "")
file.copy(paste0(appData, "pisa2025variables.csv"), paste0(staticData, "pisa2025variables.csv"), overwrite = TRUE)

#### checks ####
cat("scores:", nrow(scores), "rows,", length(unique(scores$Country)), "countries\n")
print(table(scores$Year))
cat("scores_en:", nrow(scoresEn), "rows,", length(unique(scoresEn$Country)), "countries\n")
cat("analyze:", nrow(analyzeData), "rows\n")
print(file.size(list.files(staticData, full.names = TRUE)) / 1e6)
print(list.files(staticData))
# Hebrew names shared by more than one country
print(countries %>% group_by(Hebrew) %>% filter(n() > 1))
