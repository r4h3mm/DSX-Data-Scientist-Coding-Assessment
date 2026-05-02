#Q2 SDTM DS Domain Creation using sdtm.oak

library(sdtm.oak)
library(pharmaverseraw)
library(dplyr)
library(lubridate)

install.packages("pharmaversesdtm")
library(pharmaversesdtm)

ds_raw<- pharmaverseraw::ds_raw

ds_raw_oak <- ds_raw %>%
  mutate(
    oak_id = row_number(),
    raw_source = 'CRF',
    patient_number = PATNUM 
  )

#define terminology
study_ct <- tibble::tibble(
  codelist_code = c("C66727","C66727","C66727","C66727","C66727",
                    "C66727","C66727","C66727","C66727","C66727", "C66727"),
  term_code = c("C41331","C25250","C28554","C48226","C48227",
                "C48250","C142185","C49628","C49632","C49634", "C25337"),
  term_value = c("ADVERSE EVENT","COMPLETED","DEATH","LACK OF EFFICACY",
                 "LOST TO FOLLOW-UP","PHYSICIAN DECISION","PROTOCOL VIOLATION",
                 "SCREEN FAILURE","STUDY TERMINATED BY SPONSOR",
                 "WITHDRAWAL BY SUBJECT", "RANDOMIZED"),
  collected_value = c("Adverse Event","Complete","Dead","Lack of Efficacy",
                      "Lost To Follow-Up","Physician Decision",
                      "Protocol Violation","Trial Screen Failure",
                      "Study Terminated By Sponsor","Withdrawal by Subject", "Randomized"),
  term_synonyms = c("ADVERSE EVENT","COMPLETE","Death",NA,NA,NA,NA,NA,NA,
                    "Discontinued Participation", NA)
)

#Derive SDTM variables 

ds <- assign_no_ct(
  tgt_dat = NULL,
  raw_dat = ds_raw_oak,
  raw_var = 'STUDY',
  tgt_var = 'STUDYID'
)

ds <- ds %>%
  mutate(DOMAIN = 'DS')

ds <- ds %>%
  mutate(USUBJID = paste0(STUDYID, '-', patient_number))

ds <- assign_no_ct(
  tgt_dat = ds, 
  raw_dat = ds_raw_oak, 
  raw_var = 'IT.DSDECOD',
  tgt_var = 'DSTERM'
)


ds <- assign_ct(
  tgt_dat = ds, 
  raw_dat = ds_raw_oak, 
  raw_var = 'IT.DSDECOD',
  tgt_var = 'DSDECOD',
  ct_spec = study_ct, 
  ct_clst = 'C66727'
)

ds <- ds %>%
  mutate(
    DSCAT = case_when(
      DSDECOD == 'RANDOMISED' ~ 'PROTOCOL MILESTONE',
      !is.na(DSDECOD) ~ 'DISPOSITION EVENT',
      TRUE ~ NA_character_
    )
  )

ds <- assign_no_ct(
  tgt_dat = ds, 
  raw_dat = ds_raw_oak,
  raw_var = 'INSTANCE',
  tgt_var = 'VISIT'
)

ds <- ds %>%
  mutate(
    VISITNUM = case_when(
      VISIT == 'Baseline' ~ 1, 
      VISIT == 'Week 2' ~ 2,
      VISIT == 'Week 4' ~ 3,
      VISIT == 'Week 6' ~ 4,
      VISIT == 'Week 8' ~ 5,
      VISIT == 'Week 12' ~ 6,
      VISIT == 'Week 16' ~ 7,
      VISIT == 'Week 20' ~ 8, 
      VISIT == 'Week 24' ~ 9,
      VISIT == 'Week 26' ~ 10, 
      VISIT == 'Retrieval' ~ 99, 
      TRUE ~ NA_real_
    )
  )

#Derive DSDTC
ds <- assign_no_ct(
  tgt_dat = ds,
  raw_dat = ds_raw_oak,
  raw_var = 'DSDTCOL',
  tgt_var = 'DSDTC'
)

#Derive DSSTDTC
ds <- assign_no_ct(
  tgt_dat = ds,
  raw_dat = ds_raw_oak,
  raw_var = 'IT.DSSTDAT',
  tgt_var = 'DSSTDTC',
)

ds <- ds %>%
  filter(!is.na(DSTERM))

#DERIVE dsseq

ds <- ds %>%
  derive_seq(
    tgt_var = 'DSSEQ',
    rec_vars = c('USUBJID', 'DSSTDTC')
  )

#Derive DSSTDY

dm <- pharmaversesdtm::dm

ds <- derive_study_day(
  sdtm_in = ds, 
  dm_domain = dm, 
  tgdt = 'DSSTDTC',
  refdt = 'RFSTDTC',
  study_day_var = 'DSSTDY'
)

#select final SDTM variables
ds_final <- ds %>%
  select(
    STUDYID, DOMAIN, USUBJID, DSSEQ,
    DSTERM, DSDECOD, DSCAT,
    VISITNUM, VISIT,
    DSDTC, DSSTDTC, DSSTDY
  )

cat('\n== DS Domain Summary ====\n')
cat('Total record:', nrow(ds_final), '\n')
cat('Unique subjects:', n_distinct(ds_final$USUBJID), '\n\n')

cat('Disposition terms (DSDECOD) :\n')
print(table(ds_final$DSDECOD, useNA = 'ifany'))

cat('\n DS domain creation complete using {sdtm.oak}!\n')

glimpse(ds_final)
head(ds_final, 15)

    