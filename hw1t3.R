library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
# Read the data
lookup <- read.csv("UID_ISO_FIPS_LookUp_Table.csv", stringsAsFactors = FALSE)
covid_data <- read.csv("time_series_covid19_confirmed_global.csv", stringsAsFactors = FALSE)

# Convert wide format to long format
covid_long <- covid_data %>%
  pivot_longer(cols = starts_with("X"), 
               names_to = "Date", 
               values_to = "Cases") %>%
  mutate(Date = as.Date(sub("X", "", Date), format="%m.%d.%y")) %>%
  rename(Country_Region = 'Country.Region')

# Merge with lookup table
merged_data <- merge(covid_long, lookup, by = "Country_Region")

# Save transformed data
# dir.create("data")
write.csv(covid_long, "data/covid_long.csv", row.names = FALSE)
write.csv(merged_data, "data/covid_merged.csv", row.names = FALSE)


# Overall change in log number of cases
# dir.create("plots")
p1.data = merged_data %>%
  select(Date, Cases) %>%
  group_by(Date) %>%
  summarise(TotalCases = sum(Cases, na.rm = TRUE)) %>%
  mutate(LogTotalCases = log1p(TotalCases))

p1 <- ggplot(p1.data, aes(x = Date, y = LogTotalCases)) +
  geom_line( alpha = 0.2) +
  geom_smooth(se = FALSE, color = "blue") +
  labs(title = "Overall Change in Log Number of COVID-19 Cases",
       x = "Date", y = "Log(Cases)") +
  theme_minimal()
p1
# ggsave("plots/overall_log_cases.png", plot = p1)

# Change in log number of cases by country
p2.data = merged_data %>%
  select(Date, Cases, Country_Region) %>%
  group_by(Country_Region) %>%
  summarise(TotalCases = sum(Cases, na.rm = TRUE)) %>%
  mutate(LogTotalCases = log1p(TotalCases))

p2 <- ggplot(p2.data, aes(x = Country_Region, y = LogTotalCases)) +
  geom_line(alpha = 0.5) +
  ggtitle("Change in Log Number of Cases by Country") +
  theme_minimal()
p2
# ggsave("plots/log_cases_by_country.png", plot = p2)

# Change in time by country of rate of infection per 100,000 cases
merged_data$Inf_rate = (merged_data$Cases / merged_data$Population) * 100000

infection_rate_by_country <- merged_data %>%
  group_by(Country_Region, Date) %>%
  summarise(TotalCases = sum(Cases, na.rm = TRUE),
            Population = sum(Population, na.rm = TRUE)) %>%
  mutate(InfectionRate = (TotalCases / Population) * 100000) %>%
  ungroup()

top_countries <- infection_rate_by_country %>%
  group_by(Country_Region) %>%
  summarise(MaxCases = max(TotalCases, na.rm = TRUE)) %>%
  top_n(10, MaxCases) %>%
  pull(Country_Region)

infection_rate_by_country.p3 <- infection_rate_by_country %>% filter(Country_Region %in% top_countries)

p3 <- ggplot(infection_rate_by_country.p3, aes(x = Date, y = InfectionRate, color = Country_Region)) +
  geom_line(alpha = 0.3) +
  labs(title = "Change in Infection Rate per 100,000 Cases",
       x = "Date", y = "Infection Rate per 100,000") +
  theme_minimal()

p3
# ggsave("plots/rate_per_100k.png", plot = p3)

