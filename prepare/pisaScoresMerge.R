# Merge the 2022 and 2025 scores (pisaScores2022_2025.R) into the app file
# Reads the 2006-2018 file of openpisa4Hebrew, writes to openpisa5Hebrew
library(tidyverse)

countryNames <- c(
  "United States" = "United States of America",
  "Hong Kong" = "Hong Kong-China",
  "Hong Kong (China)" = "Hong Kong-China",
  "Macao" = "Macao-China",
  "Macao (China)" = "Macao-China",
  "Türkiye" = "Turkey",
  "Czechia" = "Czech Republic",
  "Republic of Moldova" = "Moldova",
  "North Macedonia" = "Macedonia",
  "Vietnam" = "Viet Nam",
  "Massachusettes (USA)" = "Massachusetts (USA)"
)

load("C:/Users/Avner/OneDrive/R/pisa/openpisa4Hebrew/data/pisaScores.rda")
load("pisaScores2022_2025.rda")

pisaScores <- pisaScores %>%
  mutate(Country = ifelse(Country %in% names(countryNames), countryNames[Country], Country)) %>%
  bind_rows(as.data.frame(pisaScores2022_2025))

print(table(pisaScores$Year))
print(pisaScores %>% count(Year, Country, Subject, GenderESCS) %>% filter(n > 1))

save(pisaScores, file = "C:/Users/Avner/OneDrive/R/pisa/openpisa5Hebrew/data/pisaScores.rda")
