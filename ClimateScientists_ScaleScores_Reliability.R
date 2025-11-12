require(mosaic)   # Load additional packages here 
library(readr)
library(haven)
library(stringr)
library(janitor)
library(tidyverse)
library(tidyr)
library(table1)
library(expss)
library(psych)
library(dplyr)
library(ggpubr)
library(ggplot2)
library(kableExtra)
library(tableone)
library(effectsize)
library(lm.beta)
library(purrr)
library(broom)
library(interactions)
library(jtools)
library(ggrain)
library(semPlot)
library(lavaan)
library(patchwork)


## Load and wrangle dataset from Time 1
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

# Descriptive stats, Time 1
myVars <- c("age", "years_working", "cbi_personal", "cbi_work", "hopeful_future_rating", "dass_total" ,"gender", "highest_ed")
catVars <- c("gender", "highest_ed")

tab1 <- print(CreateTableOne(vars = "age", strata = "gender", data = Jude_thesis_dataset))
tab2 <- print(CreateTableOne(vars = myVars, data = Jude_thesis_dataset, factorVars = catVars, ), showAllLevels = TRUE)

# Print tables to console 
tab1

tab2

## DASS reliability
depression <- select(Jude_thesis_dataset, dass_3r, dass_5r, dass_10r, dass_13r, dass_16r, dass_17r, dass_21r) #each number refers to the column
anxiety <- select(Jude_thesis_dataset, dass_2r, dass_4r, dass_7r, dass_9r, dass_15r, dass_19r, dass_20r)
stress <- select(Jude_thesis_dataset, dass_1r, dass_6r, dass_8r, dass_11r, dass_12r, dass_14r, dass_18r)

dep_alpha <- alpha(depression)
anx_alpha <- alpha(anxiety)
str_alpha <- alpha(stress)

## CBI reliability
personal_burnout <- select(Jude_thesis_dataset, cbi_p_1r, cbi_p_2r, cbi_p_3r, cbi_p_4r, cbi_p_5r, cbi_p_6r)
work_burnout <- select(Jude_thesis_dataset, cbi_w_1r, cbi_w_2r, cbi_w_3r, cbi_w_4r, cbi_w_5r, cbi_w_6r, cbi_w_7rr)

cbi_pers_alpha <- alpha(personal_burnout)
cbi_work_alpha <- alpha(work_burnout, check.keys = TRUE)

tab3 <- print(dep_alpha$total)
tab4 <- print(anx_alpha$total)
tab5 <- print(str_alpha$total)

tab6 <- print(cbi_pers_alpha$total)
tab7 <- print(cbi_work_alpha$total)

# Print tables to console 
tab3
tab4
tab5
tab6
tab7

## PART 2 - 2025 data

Climate_data_new <- read_sav('Data/Climate_data_new_1.sav')

Climate_data_new <- clean_names(Climate_data_new) # use janitor to clean column names

## Wrangle data 


Climate_data_new <- filter(Climate_data_new, progress>40 & distribution_channel!='anonymous') # Filter out partial responders and one who somehow arrived via an anonymous link

val_lab(Climate_data_new$gender) = num_lab("
             1 Male
             2 Female   
             3 Other    ")  # Add value labels

val_lab(Climate_data_new$education) = num_lab("
             5 Doctoral Degree
             4 Masters Degree
             3 Honours/graduate diploma
             2 Bachelor degree
             1 Other    ") 

Climate_data_new <- Climate_data_new %>%
  mutate(gender = na_if(gender, 4))

## DASS reliability
depression <- select(Climate_data_new, dass21_3, dass21_5, dass21_10, dass21_13, dass21_16, dass21_17, dass21_21) #each number refers to the column
anxiety <- select(Climate_data_new, dass21_2, dass21_4, dass21_7, dass21_9, dass21_15, dass21_19, dass21_20)
stress <- select(Climate_data_new, dass21_1, dass21_6, dass21_8, dass21_11, dass21_12, dass21_14, dass21_18)

dep_alpha <- alpha(depression)
anx_alpha <- alpha(anxiety)
str_alpha <- alpha(stress)

keys_dass <- c(1,1,1,1,1,1,1)

dep_scores<- scoreItems(keys_dass, depression, totals=TRUE)
anx_scores<- scoreItems(keys_dass, anxiety, totals=TRUE)
str_scores<- scoreItems(keys_dass, stress, totals=TRUE)

Climate_data_new$dass_depression <- dep_scores$scores[,1]
Climate_data_new$dass_anxiety <- anx_scores$scores[,1]
Climate_data_new$dass_stress <- str_scores$scores[,1]
Climate_data_new$dass_total <- (Climate_data_new$dass_depression+ Climate_data_new$dass_anxiety+ Climate_data_new$dass_stress) # to do: make this nicer using dplyr. 

## CBI reliability
personal_burnout <- select(Climate_data_new, cbi_personal_1, cbi_personal_2, cbi_personal_3, cbi_personal_4, cbi_personal_5, cbi_personal_6)
work_burnout <- select(Climate_data_new, cbi_work1_1, cbi_work1_2, cbi_work1_3, cbi_work2_1, cbi_work2_2, cbi_work2_3, cbi_work2_4)

keys_cbi_personal <- c(1,1,1,1,1,1)
keys_cbi_work <- c(1,1,1,1,1,1,-1) # It seems fairly clear that the last item on this should be reverse  scored. 


## CBI scale scores
cbi_pers_alpha <- alpha(personal_burnout)
cbi_work_alpha <- alpha(work_burnout,  keys=keys_cbi_work)

tab2_3 <- print(dep_alpha$total)
tab2_4 <- print(anx_alpha$total)
tab2_5 <- print(str_alpha$total)

tab2_6 <- print(cbi_pers_alpha$total)
tab2_7 <- print(cbi_work_alpha$total)


cbi_pers_scores<- scoreItems(keys_cbi_personal, personal_burnout, totals=FALSE)
cbi_work_scores<- scoreItems(keys_cbi_work, work_burnout, totals=FALSE)

Climate_data_new$cbi_personal_mean <- cbi_pers_scores$scores[,1]
Climate_data_new$cbi_work_mean <- cbi_work_scores$scores[,1]

## Hogg Scale reliability and scoring 
hogg_scale_total <- select(Climate_data_new, hogg_scale_1, hogg_scale_2, hogg_scale_3, hogg_scale_4, hogg_scale_5, hogg_scale_6, hogg_scale_7, hogg_scale_8, hogg_scale_9, hogg_scale_10, hogg_scale_11, hogg_scale_12, hogg_scale_13)
keys_hogg_total <- c(1,1,1,1,1,1,1,1,1,1,1,1,1)

hogg_scale_affective <- select(Climate_data_new, hogg_scale_1, hogg_scale_2, hogg_scale_3, hogg_scale_4)
keys_hogg_affective <- c(1,1,1,1)

hogg_scale_rumination <- select(Climate_data_new, hogg_scale_5, hogg_scale_6, hogg_scale_7)
hogg_scale_behavioural <- select(Climate_data_new, hogg_scale_8, hogg_scale_9, hogg_scale_10)
hogg_scale_PI <- select(Climate_data_new, hogg_scale_11, hogg_scale_12, hogg_scale_13)
keys_hogg_other <- c(1,1,1)

hogg_total_scores<- scoreItems(keys_hogg_total, hogg_scale_total, totals=TRUE)
Climate_data_new$hogg_total_score <- hogg_total_scores$scores[,1]
hogg_total_alpha <- alpha(hogg_scale_total)

hogg_affective_scores<- scoreItems(keys_hogg_affective, hogg_scale_affective)
Climate_data_new$hogg_affective_score <- hogg_affective_scores$scores[,1]
hogg_affective_alpha <- alpha(hogg_scale_affective)

hogg_rumination_scores<- scoreItems(keys_hogg_other, hogg_scale_rumination)
Climate_data_new$hogg_rumination_score <- hogg_rumination_scores$scores[,1]
hogg_rumination_alpha <- alpha(hogg_scale_rumination)

hogg_behavioural_scores<- scoreItems(keys_hogg_other, hogg_scale_behavioural)
Climate_data_new$hogg_behavioural_score <- hogg_behavioural_scores$scores[,1]
hogg_behavioural_alpha <- alpha(hogg_scale_behavioural)

hogg_PI_scores<- scoreItems(keys_hogg_other, hogg_scale_PI)
Climate_data_new$hogg_PI_score <- hogg_PI_scores$scores[,1]
hogg_PI_alpha <- alpha(hogg_scale_PI)

## Coping scale 

coping_PF <- select(Climate_data_new, coping_1, coping_2, coping_3)
coping_EF <- select(Climate_data_new, coping_4, coping_5, coping_6, coping_7)
coping_avoidance <- select(Climate_data_new, coping_8, coping_9, coping_10, coping_11)

keys_coping_pf <- c(1,1,1)
keys_coping_other <- c(1,1,1,1)

coping_PF_scores<- scoreItems(keys_coping_pf, coping_PF)
coping_EF_scores<- scoreItems(keys_coping_other, coping_EF)
coping_avoidance_scores<- scoreItems(keys_coping_other, coping_avoidance)

Climate_data_new$coping_PF_score <- coping_PF_scores$scores[,1]
Climate_data_new$coping_EF_score <- coping_EF_scores$scores[,1]
Climate_data_new$coping_avoidance_score <- coping_avoidance_scores$scores[,1]

coping_PF_alpha <- alpha(coping_PF)
coping_EF_alpha <- alpha(coping_EF)
coping_avoidance_alpha <- alpha(coping_avoidance)


## SPOS scale

SPOS_scale <- select (Climate_data_new,  spos_1, spos_2,spos_3, spos_4,spos_5, spos_6, spos_7, spos_8)

keys_spos <- c(1,-1,-1,1,-1,1,-1,1) # items 2, 3, 5 and 7 are reverse coded 
SPOS_scores<- scoreItems(keys_spos, SPOS_scale)
Climate_data_new$SPOS_score <- SPOS_scores$scores[,1]
SPOS_alpha <- alpha(SPOS_scale, keys=keys_spos)

## SWEMWBS scale
SWEMWS_scale <- select (Climate_data_new,  swemws_1, swemws_2,swemws_3, swemws_4,swemws_5, swemws_6, swemws_7)
keys_swemws <- c(1,1,1,1,1,1,1)
SWEMWS_scores<- scoreItems(keys_swemws, SWEMWS_scale)
Climate_data_new$SWEMWS_score <- SWEMWS_scores$scores[,1]
SWEMWS_alpha <- alpha(SWEMWS_scale)



## Work as meaning inventory - WAMI 

## WAMI scale
WAMI_scale <- select (Climate_data_new,  wami_1, wami_2,wami_3, wami_4,wami_5, wami_6, wami_7, wami_8, wami_9, wami_10)
keys_wami <- c(1,1,-1,1,1,1,1,1,1,1)
wami_scores<- scoreItems(keys_wami, WAMI_scale, totals=TRUE)
Climate_data_new$WAMI_score <- wami_scores$scores[,1]
WAMI_alpha <- alpha(WAMI_scale, keys_wami)

## HYPOTHESIS TESTING! 

## Select variables common to both datasets 

Time1 <- select(Jude_thesis_dataset, age, gender, gender_other, country_residence, country_work, nature_work, agree_ipcc, noagree_ipcc, complicated_ipcc, cbi_personal, cbi_work, dass_depression, dass_anxiety, dass_stress, dass_total, hopeful_future_rating, worried_future)

# Add IDs to Time 1 data as they don't seem to have been included from Qualtrics
# Function from https://samfirke.com/2018/08/22/generating-unique-ids-using-r/

create_unique_ids <- function(n, seed_no = 1, char_len = 10){
  set.seed(seed_no)
  pool <- c(letters, LETTERS, 0:9)
  
  res <- character(n) # pre-allocating vector is much faster than growing it
  for(i in seq(n)){
    this_res <- paste0(sample(pool, char_len, replace = TRUE), collapse = "")
    while(this_res %in% res){ # if there was a duplicate, redo
      this_res <- paste0(sample(pool, char_len, replace = TRUE), collapse = "")
    }
    res[i] <- this_res
  }
  res
}

Time1$response_id <- create_unique_ids(nrow(Time1), seed = 23)

Time1$time <- 1

# Select matching data from Time 2

Time2 <- select(Climate_data_new, response_id, age, gender, gender_3_text, geographic_location, work_location, nature_of_role, ipcc, ipcc_2_text, ipcc_3_text, cbi_personal_mean, cbi_work_mean, dass_depression, dass_anxiety, dass_stress, dass_total, hope_1, worry_1 )

# Rename variables at Time 2 to match Time 1 
Time2 <- Time2 %>% rename(gender_other = gender_3_text,
                    country_residence = geographic_location,
                    country_work = work_location,
                    nature_work = nature_of_role, 
                    agree_ipcc = ipcc,
                    noagree_ipcc = ipcc_2_text,
                    complicated_ipcc = ipcc_3_text, 
                    cbi_personal = cbi_personal_mean, 
                    cbi_work = cbi_work_mean, 
                    hopeful_future_rating = hope_1, 
                    worried_future = worry_1)

Time2$time <- 2

## Combine datasets for comparing time 1 and time 2

All_data <- rbind(Time1, Time2)

All_data$time <- as.factor(All_data$time) # make it a factor

# Hypothesis 1: people will show more distress at Time 2 compared to Time 1 

## Check assumptions = data are skewed! 
All_data %>%
  group_by(
    time
  ) %>%
  summarise(
    `W Stat` = shapiro.test(dass_depression)$statistic,
    p.value = shapiro.test(dass_depression)$p.value
  )

## Overall DASS (mann-whitney U as per prereg)
t_dass <- wilcox.test(dass_total~time, data = All_data, alternative = "less", exact = FALSE, conf.int = TRUE, na.rm = TRUE)

## Subscales (as in preregistration)
t_depression <- wilcox.test(dass_depression~time, data = All_data,alternative = "less", exact = FALSE, conf.int = TRUE, na.rm = TRUE)
t_anxiety <- wilcox.test(dass_anxiety~time, data = All_data,alternative = "less", exact = FALSE, conf.int = TRUE, na.rm = TRUE)
t_stress <- wilcox.test(dass_stress~time, data = All_data,alternative = "less", exact = FALSE, conf.int = TRUE, na.rm = TRUE)

depression_plot <- ggplot(All_data, aes(x = time, y = dass_depression, fill = 	time)) +
  geom_rain(rain.side = 'l', alpha = .7) + scale_fill_brewer(palette = 'Set1')+ylab('DASS depression score') + theme_classic()

depression_plot

anxiety_plot <- ggplot(All_data, aes(x = time, y = dass_anxiety, fill = 	time)) +
  geom_rain(rain.side = 'l', alpha = .7) + scale_fill_brewer(palette = 'Set1')+ylab('DASS anxiety score') + theme_classic()

anxiety_plot

stress_plot <- ggplot(All_data, aes(x = time, y = dass_stress, fill = 	time)) +
  geom_rain(rain.side = 'l', alpha = .7) + scale_fill_brewer(palette = 'Set1')+ylab('DASS stress score') + theme_classic()

stress_plot


# Hypothesis 2: people will show higher levels of personal burnout at Time 2 compared to Time 1 
t_cbi_pers <- t_test(cbi_personal~time, data = All_data, alternative = "less")

# People will show higher levels of work burnout at Time 2 compared to Time 1 
t_cbi_work <- t_test(cbi_work~time, data = All_data, alternative = "less")


# Hypothesis 3 (US-based vs. non-US-Based: 

# make new variable for US vs. non-US

Climate_data_new$USA <- str_detect(Climate_data_new$work_location, "US")

# checkvars <- select(Climate_data_new, work_location, USA) # check we got them all? 

hyp3 <- glm(SWEMWS_score ~ USA + age + gender ,
                family = gaussian, data = Climate_data_new)
summary(hyp3)

wellbeing_plot <- ggplot(Climate_data_new, aes(x = USA, y = SWEMWS_score, fill = 	USA)) +
  geom_rain(rain.side = 'l', alpha = .7) + theme_classic() + scale_fill_brewer(palette = 'Dark2') + ylab('Wellbeing score')

wellbeing_plot


# Hypothesis 4: People will show higher personal than work burnout 

t_burnout_pers_vs_work <- t_test(All_data$cbi_personal, All_data$cbi_work, paired = TRUE, alternative = 'greater')

# Hypothesis 5: coping styles and well-being

model2 <- SWEMWS_score~coping_PF_score + coping_EF_score + coping_avoidance_score + age + gender
centData <- lapply(Climate_data_new[, all.vars(model2)], center) # Center the relevant variables (should we really center gender?? mmmm)

hyp5 <- lm(SWEMWS_score ~ coping_PF_score + coping_EF_score + coping_avoidance_score + age + gender , data = as.data.frame(centData))
summary(hyp5)

# Hypothesis 6: Organisational support will moderate the relationship between work burnout and well-being 

model3 <- SWEMWS_score~cbi_work_mean*SPOS_score + age + gender
centData3 <- lapply(Climate_data_new[, all.vars(model3)], center) # Center the relevant variables

hyp6 <- lm(SWEMWS_score ~ cbi_work_mean*SPOS_score + age + gender, data = as.data.frame(centData3))
summary(hyp6)

# Let's have a look at that very strong correlation. Oooof shared method variance much? 
wellbeing_plot <- ggscatter(Climate_data_new, x = 'cbi_work_mean', y = 'SWEMWS_score',
          color = 'darkred', shape = 21, size = 2, 
          add = 'reg.line', conf.int = TRUE, cor.coef = TRUE, 
          cor.coeff.args = list(method = "spearman", label.x = 65, label.sep = "\n")) + xlab ('Cognitive burnout (work) score') + ylab('Wellbeing score')

wellbeing_plot

# Confirmatory factor analysis of coping scales

# set model
coping_model <- 'Coping_PF =~ coping_1 + coping_2 + coping_3
  Coping_EF =~ coping_4 + coping_5 + coping_6 + coping_7
  Coping_AV =~ coping_8 + coping_9 + coping_10 + coping_11
'

fit <- cfa(coping_model,                                                 # compute CFA
           data = Climate_data_new,
           estimator ="MLR", 
           missing = "ML")

# analysis summary
cfa_results <- summary(fit,                                                     
        fit.measures = TRUE,                                                                
        standardized = TRUE)

# respecify model? coping_8 has a loading of .291 on the latent variable of avoidance, which is a bit low. 
coping_model_respecified <- 'Coping_PF =~ coping_1 + coping_2 + coping_3
  Coping_EF =~ coping_4 + coping_5 + coping_6 + coping_7
  Coping_AV =~ coping_9 + coping_10 + coping_11
'

fit_respecified <- cfa(coping_model_respecified,                                                 # compute CFA
           data = Climate_data_new,
           estimator ="MLR", 
           missing = "ML")

# analysis summary
cfa_results_respecified <- summary(fit_respecified,                                                     
                       fit.measures = TRUE,                                                                
                       standardized = TRUE)
# compare models
anova(fit,                                                 
      fit_respecified)


# check modification indices - not sure we really need to do this in this study? 
mi <- modificationIndices(fit_respecified)                    
head(mi)
mi_sorted_by_epc <- mi[order(mi$sepc.all, decreasing = TRUE), ]
head(mi_sorted_by_epc)

# path diagram of final model
semPaths(fit_respecified,                
         whatLabels = "std",
         intercepts = FALSE,
         layout = "tree",
         style = "lisrel")
