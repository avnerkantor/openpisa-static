# Scores for PISA 2022 and 2025, same structure as pisaScores.rda
# Same logic as pisa2018Scores.R: mean of the plausible values per student,
# then weighted mean by country, gender and ESCS group (cutoffs -0.2 and 0.7)
library(tidyverse)
library(haven)

files <- c(
  "2022" = "C:/Users/Avner/PISA2022_data/CY08MSP_STU_QQQ.SAV",
  "2025" = "C:/Users/Avner/PISA2025_data/CY09_MS_STU_PUF/CY09_MS_STU_PUF.sav"
)

scoresYear <- function(file, year) {
  students <- read_sav(file, col_select = c(CNT, ST004D01T, ESCS, W_FSTUWT,
                                            matches("^PV([1-9]|10)(MATH|READ|SCIE)$")))
  cat(year, "students:", nrow(students), "\n")
  print(attr(students$ST004D01T, "labels"))

  data <- students %>%
    transmute(
      Country = as.character(as_factor(CNT)),
      Gender = case_when(ST004D01T == 1 ~ "Female", ST004D01T == 2 ~ "Male"),
      ESCS = case_when(ESCS < -0.2 ~ "Low", ESCS > 0.7 ~ "High", !is.na(ESCS) ~ "Medium"),
      W_FSTUWT = as.numeric(W_FSTUWT),
      Math = rowMeans(across(matches("^PV[0-9]+MATH$"))),
      Reading = rowMeans(across(matches("^PV[0-9]+READ$"))),
      Science = rowMeans(across(matches("^PV[0-9]+SCIE$")))
    ) %>%
    gather("Subject", "value", Math, Reading, Science)

  groupMean <- function(df, ...) {
    df %>% group_by(Country, Subject, ...) %>%
      summarise(Average = weighted.mean(x = value, w = W_FSTUWT, na.rm = TRUE), .groups = "drop")
  }

  bind_rows(
    groupMean(data) %>% mutate(Gender = "0", ESCS = "0"),
    groupMean(data %>% filter(!is.na(Gender)), Gender) %>% mutate(ESCS = "0"),
    groupMean(data %>% filter(!is.na(ESCS)), ESCS) %>% mutate(Gender = "0"),
    groupMean(data %>% filter(!is.na(Gender), !is.na(ESCS)), Gender, ESCS)
  ) %>%
    mutate(Year = year,
           GenderESCS = paste0(ifelse(Gender == "0", "General", Gender), ifelse(ESCS == "0", "", ESCS))) %>%
    select(Year, Country, Subject, Gender, ESCS, Average, GenderESCS)
}

# country names changed over the years, use the names of countries.csv
# (also needed for the old rows of pisaScores when the files are merged)
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
fixCountryNames <- function(df) {
  df %>% mutate(Country = ifelse(Country %in% names(countryNames), countryNames[Country], Country))
}

pisaScores2022_2025 <- bind_rows(scoresYear(files["2022"], 2022), scoresYear(files["2025"], 2025)) %>%
  fixCountryNames()

save(pisaScores2022_2025, file = "pisaScores2022_2025.rda")

#### checks ####
load("C:/Users/Avner/OneDrive/R/pisa/openpisa4Hebrew/data/pisaScores.rda")
countries <- read_csv("C:/Users/Avner/OneDrive/R/pisa/openpisa4Hebrew/data/countries.csv")

# country names that the app will not recognise
pisaScores2022_2025 %>% distinct(Year, Country) %>% filter(!Country %in% countries$Country) %>% print(n = 100)

# renamed countries, years with data after the fix
pisaScores %>% fixCountryNames() %>% bind_rows(pisaScores2022_2025) %>%
  filter(Country %in% countryNames) %>% distinct(Country, Year) %>%
  group_by(Country) %>% summarise(years = paste(sort(Year), collapse = " ")) %>% print()

# Israel, all years
pisaScores %>% bind_rows(pisaScores2022_2025) %>% as_tibble() %>%
  filter(Country == "Israel", Subject %in% c("Math", "Reading", "Science")) %>%
  mutate(Average = round(Average)) %>%
  select(Year, Subject, GenderESCS, Average) %>%
  spread(Year, Average) %>% print(n = 40)
