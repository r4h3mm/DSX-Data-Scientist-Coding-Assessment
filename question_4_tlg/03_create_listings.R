#AE listing using gt

library(pharmaverseadam)
library(dplyr)
library(gt)

#load data
adae <- pharmaverseadam::adae

# Filter for treatment-emergent AEs and select relevant columns
ae_listing <- adae %>%
  filter(TRTEMFL == "Y") %>%
  select(
    USUBJID,
    ACTARM,
    AETERM,
    AESEV,
    AEREL,
    AESTDTC,
    AEENDTC
  ) %>%
  arrange(USUBJID, AESTDTC) %>%
  # Rename for display
  rename(
    `Subject ID` = USUBJID,
    Treatment = ACTARM,
    `AE Term` = AETERM,
    Severity = AESEV,
    `Relationship to Drug` = AEREL,
    `Start Date` = AESTDTC,
    `End Date` = AEENDTC
  )

#Create GT table
listing_table <- ae_listing %>%
  gt() %>%
  tab_header(
    title = "Listing of Treatment-Emergent Adverse Events by Subject",
    subtitle = "Excluding Follow-up Adverse Follow-up Adverse Events"
  ) %>%
  tab_options(
    table.font.size = 10,
    heading.title.font.size = 14,
    data_row.padding = px(3)
  )

# Print table
print(listing_table)

gtsave(listing_table, "question_4_tlg/ae_listings.html")

cat("\n✓ Listing created and saved to question_4_tlg/ae_listings.html\n")
