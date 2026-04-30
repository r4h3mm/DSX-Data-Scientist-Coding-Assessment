#Summary table 

install.packages('pharmaverseadam')
library(pharmaverseadam)
library(gtsummary)
library(dplyr)
library(gt)

#load ADAE and ADSL datasets
adae <- pharmaverseadam::adae
adsl<- pharmaverseadam::adsl

#Filter for treatment-emergent AEs only 
adae_teae <- adae %>%
  filter(TRTEMFL == 'Y')

#Total sibjects per treatment arm from ADSL
adsl_summary <- adsl %>%
  count(ACTARM, name = 'N') %>%
  mutate(ACTARM_label =  paste0(ACTARM, "\nN = ", N))

#Summary by System Organ Class

#count unique subjects with each SOC per treatment
ae_by_soc <- adae_teae %>%
  #Unqiue subject-SOC combinations per treatment
  distinct(USUBJID, ACTARM, AESOC) %>%
  #Count subjects per soc and treatment 
  count(AESOC, ACTARM, name = 'n_subjects') %>%
  #Add total N per treatment from ADSL 
  left_join(adsl %>% count(ACTARM, name = 'N'), by = 'ACTARM') %>%
  #Calculate percentage 
  mutate(pct = (n_subjects / N) * 100) %>%
  #Create display format
  mutate(display = paste0(n_subjects, " (", round(pct, 1), "%)"))

# Add overall TEAE row
overall_teae <- adae_teae %>%
  distinct(USUBJID, ACTARM) %>%
  count(ACTARM, name = "n_subjects") %>%
  left_join(adsl %>% count(ACTARM, name = "N"), by = "ACTARM") %>%
  mutate(pct = (n_subjects / N) * 100,
         display = paste0(n_subjects, " (", round(pct, 1), "%)"),
         AESOC = "Treatment Emergent AEs")

# Combine
ae_summary <- bind_rows(overall_teae, ae_by_soc) %>%
  # Pivot to wide format for table
  select(AESOC, ACTARM, display) %>%
  tidyr::pivot_wider(names_from = ACTARM, values_from = display, values_fill = "0 (0%)")

#Create Table 
ae_table <- ae_summary %>%
  gt() %>%
  tab_header(
    title = "Treatment-Emergent Adverse Events by System Organ Class",
    subtitle = "Safety Population"
  ) %>%
  cols_label(
    AESOC = "Primary System Organ Class\nReported Term for the Adverse Event"
  ) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(rows = AESOC == "Treatment Emergent AEs")
  ) %>%
  tab_options(
    table.font.size = 12,
    heading.title.font.size = 14
  )

# Print the table
ae_table

#Save as HTML 
gtsave(ae_table, "question_4_tlg/ae_summary_table.html")

cat("\n✓ Summary table created and saved to question_4_tlg/ae_summary_table.html\n")