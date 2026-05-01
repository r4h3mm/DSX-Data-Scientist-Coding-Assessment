install.packages('admiral')
library(admiral)
library(pharmaversesdtm)
library(dplyr)
library(lubridate)

#Loading SDTM datasets
dm <- pharmaversesdtm::dm 
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae

#Inpsecting datasets
glimpse(dm)
glimpse(vs)
glimpse(ex)
glimpse(ds)
glimpse(ae)

#Derive AGER9 and AGEGR9N
adsl <- dm %>%
  mutate(
    AGEGR9 = case_when(
      AGE < 18 ~ '<18',
      AGE >=18 & AGE <= 50 ~ '18-50',
      AGE > 50 ~ '>50',
      TRUE ~ NA_character_
    ),
    AGEGR9N = case_when(
      AGE < 18 ~ 1,
      AGE >= 18 & AGE <= 50 ~ 2,
      AGE > 50 ~ 3,
      TRUE ~ NA_real_
    )
    
  )

#Derive TRTSDTM 
ex_valid <- ex %>%
  filter(
    (EXDOSE > 0) | (EXDOSE == 0 & grepl("PLACEBO", EXTRT, ignore.case = TRUE))
  ) %>%
  arrange(USUBJID, EXSTDTC) %>%
  group_by(USUBJID) %>%
  slice(1) %>%
  ungroup() %>%
  select(USUBJID, EXSTDTC)

# Merge first exposure to ADSL and derive datetime with imputation
adsl <- adsl %>%
  left_join(ex_valid, by = "USUBJID") %>%
  derive_vars_dtm(
    new_vars_prefix = "TRTS",
    dtc = EXSTDTC,
    date_imputation = "first",
    time_imputation = "first",
    flag_imputation = "time"
  ) %>%
  # Remove the temporary EXSTDTC column
  select(-EXSTDTC)

#ITTFL 
adsl <- adsl %>%
  mutate(
    ITTFL = if_else(!is.na(ARM), 'Y', 'N')
  )

#Subjects with abnormal bp 
abnormal_sbp <- vs %>%
  filter( 
    VSTESTCD == 'SYSBP',
    VSSTRESU == 'mmHg',
    (VSSTRESN < 100 | VSSTRESN >= 140)
    ) %>%
  distinct(USUBJID) %>%
  mutate(ABNSBPFL = "Y")

# Merge back to ADSL
adsl <- adsl %>%
  left_join(abnormal_sbp, by = "USUBJID") %>%
  mutate(ABNSBPFL = if_else(is.na(ABNSBPFL), "N", ABNSBPFL))

#Last known alive date 
# Get last complete VS date with valid test result
last_vs <- vs %>%
  filter(
    !is.na(VSDTC),
    (!is.na(VSSTRESN) | !is.na(VSSTRESC))
  ) %>%
  mutate(VS_DATE = convert_dtc_to_dt(VSDTC)) %>%
  filter(!is.na(VS_DATE)) %>%
  group_by(USUBJID) %>%
  summarise(LAST_VS = max(VS_DATE, na.rm = TRUE), .groups = "drop")

# Get last complete AE onset date
last_ae <- ae %>%
  filter(!is.na(AESTDTC)) %>%
  mutate(AE_DATE = convert_dtc_to_dt(AESTDTC)) %>%
  filter(!is.na(AE_DATE)) %>%
  group_by(USUBJID) %>%
  summarise(LAST_AE = max(AE_DATE, na.rm = TRUE), .groups = "drop")

# Get last complete disposition date
last_ds <- ds %>%
  filter(!is.na(DSSTDTC)) %>%
  mutate(DS_DATE = convert_dtc_to_dt(DSSTDTC)) %>%
  filter(!is.na(DS_DATE)) %>%
  group_by(USUBJID) %>%
  summarise(LAST_DS = max(DS_DATE, na.rm = TRUE), .groups = "drop")

# Get last treatment administration date (from valid doses)
last_ex <- ex_valid %>%
  mutate(EX_DATE = convert_dtc_to_dt(EXSTDTC)) %>%
  filter(!is.na(EX_DATE)) %>%
  group_by(USUBJID) %>%
  summarise(LAST_EX = max(EX_DATE, na.rm = TRUE), .groups = "drop")


# Merge all last dates and take maximum
adsl <- adsl %>%
  left_join(last_vs, by = "USUBJID") %>%
  left_join(last_ae, by = "USUBJID") %>%
  left_join(last_ds, by = "USUBJID") %>%
  left_join(last_ex, by = "USUBJID") %>%
  rowwise() %>%
  mutate(
    LSTALVDT = max(c(LAST_VS, LAST_AE, LAST_DS, LAST_EX), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  select(-LAST_VS, -LAST_AE, -LAST_DS, -LAST_EX)

#CARPOPFL 

#those with cardiac AEs
cardiac_ae <- ae %>%
  filter(toupper(AESOC) == 'CARDIAC DISORDERS') %>%
  distinct(USUBJID) %>%
  mutate(CARPOPFL = 'Y')

adsl <- adsl %>%
  left_join(cardiac_ae, by = "USUBJID")

adsl <- adsl %>%
  select(
    STUDYID, USUBJID, SUBJID, SITEID, 
    AGE, SEX, RACE, ETHNIC,
    ARM, ACTARM,
    AGEGR9, AGEGR9N,
    TRTSDTM, TRTSTMF,
    ITTFL, ABNSBPFL, CARPOPFL, 
    LSTALVDT,
    RFSTDTC, RFENDTC, RFXSTDTC, RFXENDTC
  )

#Output

#Output
cat("\n=== ADSL Summary ===\n")
cat("Total subjects:", nrow(adsl), "\n\n")

cat("Age groups:\n")
print(table(adsl$AGEGR9, adsl$AGEGR9N, useNA = "ifany"))

cat("\nITT Flag:\n")
print(table(adsl$ITTFL, useNA = "ifany"))

cat("\nAbnormal Systolic BP Flag:\n")
print(table(adsl$ABNSBPFL, useNA = "ifany"))

cat("\nCardiac AE Flag:\n")
print(table(adsl$CARPOPFL, useNA = "ifany"))

cat("\nTreatment Start Datetime - first 5 subjects:\n")
print(head(adsl %>% select(USUBJID, TRTSDTM, TRTSTMF), 5))

cat("\nLast Known Alive Date - summary:\n")
print(summary(adsl$LSTALVDT))

cat("\n✓ ADSL creation complete!\n")

#display rows
glimpse(adsl)
head(adsl, 10)
