# Regression table for PISA 2025, same logic as analyzeData5.R:
# for every country and every index, lm(score ~ index) with student weights
library(tidyverse)
library(haven)

stuFile <- "C:/Users/Avner/PISA2025_data/CY09_MS_STU_PUF/CY09_MS_STU_PUF.sav"
schFile <- "C:/Users/Avner/PISA2025_data/CY09_MS_SCH_PUF/CY09_MS_SCH_PUF.sav"

# nominal codes (language, occupation, programme, country of birth) are left out
students2025 <- read_sav(stuFile, col_select = c(
  CNT, CNTSCHID, STRATUM, W_FSTUWT, matches("^PV([1-9]|10)(MATH|READ|SCIE)$"),
  EFFORT1:BSMJ, BICT_P1:ICTDISTR, IMMIG, P1ISCED:PAREXPT, REPEAT:WORKPAY, AGE, GRADE))
schools2025 <- read_sav(schFile, col_select = c(CNT, CNTSCHID, ABGSCIE:TDTEST))

stuVars <- setdiff(names(students2025), c("CNT", "CNTSCHID", "STRATUM", "W_FSTUWT",
                                          grep("^PV", names(students2025), value = TRUE)))
schVars <- setdiff(names(schools2025), c("CNT", "CNTSCHID"))

getLabels <- function(df, vars) {
  data.frame(ID = vars, index = sapply(vars, function(v) attr(df[[v]], "label")), row.names = NULL)
}
analyzeVariables <- bind_rows(getLabels(students2025, stuVars), getLabels(schools2025, schVars)) %>%
  mutate(index = str_squish(str_remove(index, "\\(WLE\\)")),
         variable = paste0(index, " (", ID, ")"))
write.csv(analyzeVariables, file = "analyzeVariables2025.csv", row.names = FALSE)

data <- students2025 %>%
  mutate(Country = as.character(as_factor(CNT)),
         Stratum = as.character(as_factor(STRATUM)),
         PVMATH = rowMeans(across(matches("^PV[0-9]+MATH$"))),
         PVREAD = rowMeans(across(matches("^PV[0-9]+READ$"))),
         PVSCIE = rowMeans(across(matches("^PV[0-9]+SCIE$")))) %>%
  select(-matches("^PV[0-9]"), -STRATUM) %>%
  left_join(schools2025, by = c("CNT", "CNTSCHID")) %>%
  zap_labels() %>%
  mutate(across(all_of(c(stuVars, schVars)), as.numeric))

# Israel by sector, from the public stratum
israel <- data %>% filter(CNT == "ISR")
print(table(israel$Stratum))
isrData <- bind_rows(
  israel %>% filter(str_detect(Stratum, "Hebrew")) %>% mutate(Country = "Israel Hebrew"),
  israel %>% filter(str_detect(Stratum, "Arabic")) %>% mutate(Country = "Israel Arabic"),
  israel %>% filter(Stratum == "Hebrew-Secular") %>% mutate(Country = "Israel Hebrew Secular"),
  israel %>% filter(str_detect(Stratum, "^Hebrew-Religious")) %>% mutate(Country = "Israel Hebrew Religious"),
  israel %>% filter(Stratum == "Hebrew Ultra-Orthodox-Females") %>% mutate(Country = "Israel Ultra Orthodox Girls")
)
print(table(isrData$Country))
data <- bind_rows(data, isrData)

subjects <- c("PVMATH", "PVREAD", "PVSCIE")
countries <- unique(data$Country)

df3 <- bind_rows(lapply(countries, function(cnt) {
  countryData <- data %>% filter(Country == cnt)
  bind_rows(lapply(c(stuVars, schVars), function(index) {
    if (length(unique(na.omit(countryData[[index]]))) < 2) return(NULL)
    bind_rows(lapply(subjects, function(sbj) {
      tryCatch({
        td <- summary(lm(countryData[[sbj]] ~ countryData[[index]], weights = countryData$W_FSTUWT))
        data.frame(Year = 2025,
                   Country = cnt,
                   subject = sbj,
                   ID = index,
                   estimate = td$coefficients[2, 1],
                   std.error = td$coefficients[2, 2],
                   t.value = td$coefficients[2, 3],
                   p.value = td$coefficients[2, 4],
                   r.squared = td$r.squared,
                   n = td$df[2])
      }, error = function(e) NULL)
    }))
  }))
}))
save(df3, file = "df3_2025.rda")

analyzeData <- df3 %>%
  mutate(Subject = case_when(subject == "PVMATH" ~ "Math", subject == "PVREAD" ~ "Reading", subject == "PVSCIE" ~ "Science")) %>%
  left_join(analyzeVariables %>% select(ID, variable), by = "ID") %>%
  mutate(stars = case_when(
    p.value < 0.01 ~ "***",
    p.value >= 0.01 & p.value < 0.05 ~ "**",
    p.value >= 0.05 & p.value < 0.1 ~ "*",
    TRUE ~ as.character(round(p.value, 2))
  )) %>%
  mutate(across(c(r.squared, t.value, estimate, std.error), ~ round(., 2))) %>%
  select(Country, Subject, variable, r.squared, p.value = stars, t.value, estimate, std.error, n)

save(analyzeData, file = "C:/Users/Avner/OneDrive/R/pisa/openpisa5Hebrew/data/analyzeData2025.rda")

#### checks ####
str(analyzeData)
cat("countries:", length(unique(analyzeData$Country)), " variables:", length(unique(analyzeData$variable)), "\n")
analyzeData %>% filter(Country == "Israel", Subject == "Math") %>% arrange(desc(r.squared)) %>% head(15) %>% print()
analyzeData %>% filter(Country == "Israel", Subject == "Math", str_detect(variable, "CLSIZE|\\(ESCS\\)")) %>% print()
