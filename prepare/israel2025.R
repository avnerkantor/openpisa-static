# Israel 2025 student file for the app (R editor and download button)
# Same layout as israel2018: Israel and the five sector groups stacked,
# gender, mean of the plausible values, weight, student and school indices
library(tidyverse)
library(haven)

stuFile <- "C:/Users/Avner/PISA2025_data/CY09_MS_STU_PUF/CY09_MS_STU_PUF.sav"
schFile <- "C:/Users/Avner/PISA2025_data/CY09_MS_SCH_PUF/CY09_MS_SCH_PUF.sav"
appData <- "C:/Users/Avner/OneDrive/R/pisa/openpisa5Hebrew/data/"

students2025 <- read_sav(stuFile, col_select = c(
  CNT, CNTSCHID, STRATUM, ST004D01T, W_FSTUWT, matches("^PV([1-9]|10)(MATH|READ|SCIE)$"),
  EFFORT1:COBN_P2))
schools2025 <- read_sav(schFile, col_select = c(CNT, CNTSCHID, ABGSCIE:TDTEST))

israel <- students2025 %>%
  filter(CNT == "ISR") %>%
  left_join(schools2025, by = c("CNT", "CNTSCHID")) %>%
  mutate(Country = "Israel",
         Stratum = as.character(as_factor(STRATUM)),
         ST04Q01 = factor(case_when(ST004D01T == 1 ~ "Female", ST004D01T == 2 ~ "Male")),
         PVREAD = rowMeans(across(matches("^PV[0-9]+READ$"))),
         PVMATH = rowMeans(across(matches("^PV[0-9]+MATH$"))),
         PVSCIE = rowMeans(across(matches("^PV[0-9]+SCIE$")))) %>%
  zap_labels() %>% zap_label() %>% zap_formats() %>%
  select(Country, Stratum, ST04Q01, PVREAD, PVMATH, PVSCIE, W_FSTUWT, EFFORT1:COBN_P2, ABGSCIE:TDTEST)

israel2025 <- bind_rows(
  israel,
  israel %>% filter(str_detect(Stratum, "Hebrew")) %>% mutate(Country = "Israel Hebrew"),
  israel %>% filter(str_detect(Stratum, "Arabic")) %>% mutate(Country = "Israel Arabic"),
  israel %>% filter(Stratum == "Hebrew-Secular") %>% mutate(Country = "Israel Hebrew Secular"),
  israel %>% filter(str_detect(Stratum, "^Hebrew-Religious")) %>% mutate(Country = "Israel Hebrew Religious"),
  israel %>% filter(Stratum == "Hebrew Ultra-Orthodox-Females") %>% mutate(Country = "Israel Ultra Orthodox Girls")
) %>%
  select(-Stratum) %>%
  as.data.frame()

save(israel2025, file = paste0(appData, "israel2025.rda"))

# names and labels of all variables in the student and school files
varLabels <- function(file) {
  df <- read_sav(file, n_max = 1)
  data.frame(ID = names(df),
             VARLABEL = sapply(df, function(x) { l <- attr(x, "label"); if (is.null(l)) NA else str_squish(l) }),
             row.names = NULL)
}
pisa2025variables <- bind_rows(varLabels(stuFile), varLabels(schFile)) %>% distinct(ID, .keep_all = TRUE)
write.csv(pisa2025variables, file = paste0(appData, "pisa2025variables.csv"), row.names = FALSE)

#### checks ####
cat(dim(israel2025), "\n"); print(table(israel2025$Country)); print(table(sapply(israel2025, function(x) class(x)[1])))
print(head(israel2025[, c("Country", "ST04Q01", "PVMATH", "W_FSTUWT", "ESCS", "CLSIZE")], 3))
israel2025 %>% group_by(Country) %>%
  summarise(n = n(), Math = round(weighted.mean(PVMATH, W_FSTUWT)), Reading = round(weighted.mean(PVREAD, W_FSTUWT)),
            Science = round(weighted.mean(PVSCIE, W_FSTUWT))) %>% print()
cat(nrow(pisa2025variables), "variables\n")
