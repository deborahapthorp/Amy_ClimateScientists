library(stringr)
library(readxl)
library(janitor)
library(tidyverse)
library(tidyr)
library(readr)

bounce_list <- read_csv("Email_bounce_list.csv")
bounce_list <- clean_names(bounce_list) # use janitor to clean column names

#Filter out those who have completed the survey and those whose emails "hard bounced"
bounce_list <- filter(bounce_list, bounce_list$status!='Email Hard Bounce'& bounce_list$status!='Survey Finished' )

bounce_list <- bounce_list %>% rename(surname = last_name) # rename to be consistent with other list 
bounce_list_selected <- bounce_list %>% select(surname, first_name, email_address) # select only the fields that both datasets share

# Write all lists to file 
write_csv(bounce_list, "Bounce list with reasons.csv")

write_csv(bounce_list_selected, "Bounce list name and email only.csv")