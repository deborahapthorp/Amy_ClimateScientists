library(stringr)
library(readxl)
library(janitor)
library(tidyverse)
library(tidyr)

Medline_with_surnames <- read_excel("Medline with surnames.xlsx") # Read in Excel file
Medline_list <- clean_names(Medline_with_surnames) # use janitor to clean column names
Medline_list$first_name <- str_trim(Medline_list$first_name) # Trim whitespace
Medline_list$email_1 <- gsub("\\.$", "", Medline_list$email_1) # get rid of full stop at end of emails
Medline_list <- Medline_list %>% rename(email = email_1) # Rename email column to match
Medline_list_selected <- Medline_list %>% select(surname, first_name, email) # Select only the columns we want
IPCC_list <- read_excel("IPCC AR6 Authors.xlsx", 
                               col_types = c("skip", "text", "text", 
                                             "text", "text", "text", "text", "text", 
                                             "text", "text", "skip")) # skip not very informative columns
IPCC_list <- clean_names(IPCC_list) # use janitor to clean column names
IPCC_list$last_name <- str_to_title(IPCC_list$last_name) # un-capitalise last names
IPCC_list <- IPCC_list %>% rename(surname = last_name) # rename to be consistent with other list 
IPCC_list_selected <- IPCC_list %>% select(surname, first_name, email) # select only the fields that both datasets share

Combined_list <- rbind(Medline_list_selected, IPCC_list_selected) # compile datasets

Combined_list <- Combined_list[!duplicated(Combined_list[c('first_name', 'surname')]),] # remove any exact duplicates

Combined_list_notMissing <- Combined_list[!is.na(Combined_list$email), ] # Select the ones who aren't missing an email 
Combined_list_missing <- Combined_list[is.na(Combined_list$email), ] # Select the ones who are missing an email

Merged_missing = merge(Combined_list_missing, IPCC_list, by.x=c('first_name', 'surname'), 
                       by.y=c('first_name', 'surname'), all.x = TRUE) # Merge missing email list with IPCC info
Merged_missing  <- Merged_missing [!duplicated(Merged_missing [c('first_name', 'surname')]),] # remove duplicates


# Write all lists to file 
write_csv(Combined_list_notMissing, "Climate_emails.csv")
write_csv(Combined_list_missing, "Climate_scientists_without_emails.csv")
write_csv(Merged_missing, "Climate_scientists_without_emails_all_info.csv")

# Add new emails

library(readr)
climate_emails <- read_csv("Climate_emails.csv")
new_emails <- read.csv("Climate_scientists_new_emails.csv")

merged_all = rbind(climate_emails, new_emails) # Merge missing email list with IPCC info

write_csv(merged_all, "Climate_scientists_final_emails.csv")

# Split emails (filtered by Qualtrics) into groups 
climate_emails_new <- read_csv("Climate_emails_final_qualtrics_download.csv")

#Split into 7 data frames - this should be properly done using lapply but I didn't have time 

df1 <- climate_emails_new[row.names(climate_emails_new) %in% 1:1000, ]
df2 <- climate_emails_new[row.names(climate_emails_new) %in% 1001:2000, ]
df3 <- climate_emails_new[row.names(climate_emails_new) %in% 2001:3000, ]
df4 <- climate_emails_new[row.names(climate_emails_new) %in% 3001:4000, ]
df5 <- climate_emails_new[row.names(climate_emails_new) %in% 4001:5000, ]
df6 <- climate_emails_new[row.names(climate_emails_new) %in% 5001:6000, ]
df7 <- climate_emails_new[row.names(climate_emails_new) %in% 6001:7000, ]
df8 <- climate_emails_new[row.names(climate_emails_new) %in% 7001:nrow(climate_emails_new), ]

write_csv(df1, "Climate_scientists_emails_1.csv")
write_csv(df2, "Climate_scientists_emails_2.csv")
write_csv(df3, "Climate_scientists_emails_3.csv")
write_csv(df4, "Climate_scientists_emails_4.csv")
write_csv(df5, "Climate_scientists_emails_5.csv")
write_csv(df6, "Climate_scientists_emails_6.csv")
write_csv(df7, "Climate_scientists_emails_7.csv")
write_csv(df8, "Climate_scientists_emails_8.csv")