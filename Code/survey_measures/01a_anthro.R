###################################################################################################################################
###################################################################################################################################
# Anthropometrics
###################################################################################################################################
here <-here::here()
###################################################################################################################################


# Load dnam individuals 

dnam <-read_csv(here::here("Data/Other", "uncchdid_w_DNAm.csv"))
names(dnam)<-"uncchdid"
# Remove the _R1 and _R2
dnam$uncchdid <-substr(dnam$uncchdid, 1, 5)
dim(dnam)

# LOad the blood draw dates, which has the sex. Merge and keep sex for DNAm

blood.draw.dates <- read_csv(here::here("Data/Other","blood.draw.dates.csv"))[,-1]
blood.draw.dates$uncchdid <-as.character(blood.draw.dates$uncchdid)


chk.bld.draw <-left_join(dnam, blood.draw.dates, by = "uncchdid") %>% 
  select(-c(dayblood:yearblood))

# Merge only male predicted so I don't lose the mispredictions from EAGE
head(chk.bld.draw)

###################################################################################################################################
###################################################################################################################################



# Calculations from: https://nutritionalassessment.mumc.nl/en/anthropometry
###################################################################################################################################
anthro <-read_dta(here::here("Data/zip_child_2005/anthdiet.DTA")) %>% 
  rename_all(tolower)  %>%
  mutate(whr = waist / hip) %>% 
  mutate(tricep_mean = rowMeans(select(., starts_with("tricep")), na.rm = TRUE)) %>%  # mean of 3 measurements in mm
  mutate(subscap_mean = rowMeans(select(., starts_with("subscap")), na.rm = TRUE)) %>%  # mean of 3 measurements in mm
  mutate(supra_mean = rowMeans(select(., starts_with("suprail")), na.rm = TRUE)) %>%  # mean of 3 measurements in mm
  mutate(arm_musc_circ = armcircm*10 - (tricep_mean * 3.14)) %>% # Upper arm muscle circ. (S) in mm: S = c - ( T * 3.14) 
  mutate(arm_musc_area = arm_musc_circ^2 / 12.56) %>% # Upper arm muscle area (M) in mm² : M = S² / 12.56
  mutate(bmi = weight/(height/100)^2) %>% 
  select(uncchdid, weight, height, bmi, waist, hip, whr, armcircm, subscap_mean, supra_mean, tricep_mean, arm_musc_area) %>% 
  na_if(., -9) %>% 
  mutate(skinfold_sum = subscap_mean + supra_mean + tricep_mean) %>% 
  filter(uncchdid %in% chk.bld.draw[chk.bld.draw$icsex == "1=male",]$uncchdid)


names(anthro)

# Calculate the density, fat-free mass, etc.
# Constants from Durnin and Womersley, 1974, (Males, Age 20-29)
# Linear regressionequationsfor the estimation of body density x 10^3(kg/m^3)
# density = c - m x log skinfold

dw_c <-1.1575
dw_m <-0.0617
# bfperc = ((4.95/density )-4.5)*100
# fatmass = (( bfperc *.01)*weight)
# ffm05 = weight-fatmass

anthro <-anthro %>% 
  mutate(logfolds = log(skinfold_sum), 
         density = dw_c - (dw_m * logfolds), 
         bfperc = ((4.95/density )-4.5)*100,
         fatmass = (( bfperc *.01)*weight),
         fatfree_mass = weight-fatmass)








# anthro %>% 
#   select(-uncchdid, -weight, -armcircm, -waist, -hip, -subscap_mean, -supra_mean, -tricep_mean) %>% 
#   psych::pairs.panels(.,method = "pearson", # correlation method
#                       hist.col = "gray80",
#                       density = TRUE,  # show density plots
#                       ellipses = TRUE, 
#                       stars = TRUE, # show correlation ellipses
#                       cex.cor = 4
#   )




# prcomp_anthro <-prcomp(anthro %>%   select(-uncchdid, -weight, -armcircm, -waist, -hip, -subscap_mean, -supra_mean, -tricep_mean)
#  , scale. = TRUE)
# ###################################################################################################################################
# # Picked the scales. 
# summary(anthro$height)
# summary(anthro$bmi)
# 
# pca_anthro <- data.frame(
#   PC1 = prcomp_anthro$x[, 1],
#   PC2 = prcomp_anthro$x[, 2],
#   height = cut(anthro$height, 
#              breaks=c(0, 160.1, 166.4, 177.4), 
#              labels=c("short","average","tall")),
#   bmi =  cut(anthro$bmi, 
#              breaks=c(0, 18.94, 22.42, 29.90), 
#              labels=c("light","average","heavy")),
#   uncchdid = anthro$uncchdid
# )
# 
# ggplot(pca_anthro, aes(x = PC1, y = anthro$bmi, label = uncchdid, color = height, shape = bmi))+
#   geom_point()+
#   ggrepel::geom_text_repel(cex = 2.5)+
#   theme_bw()+
#   scale_color_brewer(palette = "Set1")
###################################################################################################################################



anthro_min <-anthro %>% 
  select(-weight, -armcircm, -waist, -hip, -skinfold_sum, -logfolds, -density) %>% 
  as_character(uncchdid)



# anthro_min %>% 
#   ggplot(., aes(whr, skinfold_sum))+
#   # ggpubr::stat_regline_equation()+
#   ggpubr::stat_cor()+
#   stat_smooth(method = "lm")+
#   geom_point()
# # Not good measures

anthro_min <-left_join(anthro_min, 
          chk.bld.draw, 
          by = 'uncchdid')



#######
anthro <-anthro_min; rm(anthro_min)

ggplot(anthro) +
  geom_histogram(aes(x = fatfree_mass))
