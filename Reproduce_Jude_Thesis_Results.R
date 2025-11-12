library(readr)
library(haven)
library(stringr)
library(janitor)
library(tidyverse)
library(tidyr)
library(tableone)
library(expss)
library(psych)
library(dplyr)
library(ggpubr)
library(ggplot2)
library(effectsize)

## Load and clean data

Jude_thesis_dataset <- read_sav("Jude-thesis-complete-dataset-edited.sav")

Jude_thesis_dataset <- clean_names(Jude_thesis_dataset) # use janitor to clean column names

val_lab(Jude_thesis_dataset$gender) = num_lab("
             1 Male
             2 Female   
             3 Other    ")  # Add value labels (not sure why they didn't come through with the import)

val_lab(Jude_thesis_dataset$highest_ed) = num_lab("
             1 Doctoral Degree
             2 Masters Degree
             3 Honours/graduate diploma
             4 Bachelor degree
             5 Other    ") 

## Descriptive stats

myVars <- c("age", "years_working", "cbi_personal", "cbi_work", "hopeful_future_rating", "dass_total" ,"gender", "highest_ed")
catVars <- c("gender", "highest_ed")

tab1 <- CreateTableOne(vars = "age", strata = "gender", data = Jude_thesis_dataset)
tab2 <- CreateTableOne(vars = myVars, data = Jude_thesis_dataset, factorVars = catVars)

## DASS reliability
depression <- select(Jude_thesis_dataset, dass_3r, dass_5r, dass_10r, dass_13r, dass_16r, dass_17r, dass_21r) #each number refers to the column
anxiety <- select(Jude_thesis_dataset, dass_2r, dass_4r, dass_7r, dass_9r, dass_15r, dass_19r, dass_20r)
stress <- select(Jude_thesis_dataset, dass_1r, dass_6r, dass_8r, dass_11r, dass_12r, dass_14r, dass_18r)

alpha(depression)
alpha(anxiety)
alpha(stress)

## CBI reliability
personal_burnout <- select(Jude_thesis_dataset, cbi_p_1r, cbi_p_2r, cbi_p_3r, cbi_p_4r, cbi_p_5r, cbi_p_6r)
work_burnout <- select(Jude_thesis_dataset, cbi_w_1r, cbi_w_2r, cbi_w_3r, cbi_w_4r, cbi_w_5r, cbi_w_6r, cbi_w_7rr)

alpha(personal_burnout)
alpha(work_burnout, check.keys = TRUE)

## Hypothesis tests - comparing means to normative sample

t_dass <- t.test(Jude_thesis_dataset$dass_total, mu=9.43)
d_dass <- Jude_thesis_dataset %>% rstatix::cohens_d(dass_total ~ 1, mu = 9.43, ci = TRUE)

t_personal_burnout <- t.test(Jude_thesis_dataset$cbi_personal, mu= 35.9)
d_personal_burnout <- Jude_thesis_dataset %>% rstatix::cohens_d(cbi_personal ~ 1, mu = 35.9, ci = TRUE)


t_work_burnout <- t.test(Jude_thesis_dataset$cbi_work, mu= 33.0)
d_work_burnout <- Jude_thesis_dataset %>% rstatix::cohens_d(cbi_work ~ 1, mu = 33, ci = TRUE)


library(broom)
library(purrr)

tab <- map_df(list(t_dass, t_personal_burnout, t_work_burnout), tidy)

tab <- tab[c("estimate", "statistic", "p.value", "conf.low", "conf.high")]

row.names(tab) <- c("DASS total","Personal Burnout","Work Burnout")

# Paired t-test 
x = Jude_thesis_dataset$cbi_personal
y = Jude_thesis_dataset$cbi_work


t_paired_cbi <- t.test(x, y, paired = TRUE)
d_paired_cbi <- effectsize::cohens_d(x, y, paired = TRUE)

# Correlation between cbi and age

cor_cbi_age <- cor.test(Jude_thesis_dataset$cbi_personal, Jude_thesis_dataset$age)

rsq_cbi_age <- cor_cbi_age$estimate^2

ggscatter(Jude_thesis_dataset, x = "age", y = "cbi_personal", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Age", ylab = "Personal Burnout")

Jude_thesis_dataset$age_c <- Jude_thesis_dataset$age - mean(Jude_thesis_dataset$age)

Jude_thesis_dataset$hope_c <- Jude_thesis_dataset$hopeful_future_rating - mean(Jude_thesis_dataset$hopeful_future_rating)

m1 <- lm(cbi_personal~age_c*hope_c, data = Jude_thesis_dataset)

library(jtools) # for summ()
summ(m1) # this isn't super informative, look up better packages

library(interactions)
p <- interact_plot(m1, pred = age_c, modx = hope_c, plot.points = TRUE)

p + xlab("Age (centered)") + ylab("Burnout") + theme_classic()