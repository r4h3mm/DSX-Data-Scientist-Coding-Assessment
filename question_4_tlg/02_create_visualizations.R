
#AE Visualisations using ggplot

library(pharmaverseadam)
library(ggplot2)
library(dplyr)
library(binom)

#Load data
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl

#Filter for treatment emergen AE
adae_teae <- adae %>%
  filter(TRTEMFL == 'Y')

#Plot 1- AE severity Distribution by treatment 
# Count AEs by severity and treatment
severity_data <- adae_teae %>%
  count(ACTARM, AESEV) %>%
  mutate(AESEV = factor(AESEV, levels = c("MILD", "MODERATE", "SEVERE")))

#Create stacked bar chart
plot1 <- ggplot(severity_data, aes(x = ACTARM, y = n, fill = AESEV)) +
  geom_bar(stat = 'identity') +
  scale_fill_manual(
    values = c('MILD' = '#F8766D', 'MODERATE'= '#00BA38', 'SEVERE' = '#619CFF'),
    name = 'Severity/Intensity'
  ) +
  labs(
    title = "AE severity distribution by treatment",
    x = "Treatment Arm",
    y = "Count of AEs"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

print(plot1)

# Save plot
ggsave("question_4_tlg/ae_severity_by_treatment.png", plot1, width = 8, height = 6, dpi = 300)

#Plot 2 - Top 10 Most Frequent AEs with 95% CI

# Get total N per treatment from ADSL
total_n <- adsl %>%
  count(ACTARM, name = "total_subjects")

# Calculate AE frequencies and get top 10
top10_aes <- adae_teae %>%
  # Count unique subjects per AE term
  distinct(USUBJID, AETERM) %>%
  count(AETERM, name = "n_subjects") %>%
  # Get top 10
  arrange(desc(n_subjects)) %>%
  slice(1:10) %>%
  pull(AETERM)

# Calculate incidence rates and CIs for top 10
ae_rates <- adae_teae %>%
  filter(AETERM %in% top10_aes) %>%
  distinct(USUBJID, AETERM) %>%
  count(AETERM, name = 'n_events') %>%
  mutate(
    total_n = nrow(adsl), #total subjects
    rate = (n_events / total_n) *100
  ) %>%
  #calcualte 95% Clopper-Pearson CI 
  rowwise()%>%
  mutate(
    ci_result = list(binom.confint(n_events, total_n, methods = 'exact')),
    lower = ci_result$lower * 100,
    upper = ci_result$upper * 100
  ) %>%
  ungroup()%>%
  select(AETERM, n_events, total_n, rate, lower, upper) %>%
  arrange(desc(rate))

#Forest plot 
plot2 <- ggplot(ae_rates, aes(x = rate, y = reorder(AETERM, rate))) +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.2) +
  labs(
    title = 'Top 10 Most Frequent Adverse Events',
    subtitle = paste0('n = ', unique(ae_rates$total_n), 'subjects; 95% Clopper-Pearson CIs'),
    x = 'Percentage of Patients (%)',
    y = ''
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    plot.subtitle = element_text(hjust = 0.5, size = 10),
    panel.grid.major.y = element_blank()
  )

print(plot2)

# Save plot
ggsave("question_4_tlg/top10_aes_with_ci.png", plot2, width = 8, height = 6, dpi = 300)

cat("\n✓ Both visualizations created and saved to question_4_tlg/\n")