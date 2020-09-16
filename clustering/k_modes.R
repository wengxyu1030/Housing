#This file is to generate cluster on NSS76 urban housing condition. 
#using k-modes

library(tidyverse)
library(cluster)
library(klaR)
library(foreign)
library(readstata13)

#load data
data_path <- "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/nss_data/NSS76/Data Output Files"
nss76_raw <- read.dta13(paste0(data_path,"/NSS76_All_clst_u.dta"))
nss76 <- nss76_raw %>%
  rename(floor = b7_14,
         wall = b7_15,
         roof = b7_16,
         kit_type = b7_12,
         dwell_type = b7_1,
         latrine = b5_26,
         water_source = b5_1)

ind <- c("floor","wall","roof", #floo,rwall,roof
         "kit_type","dwell_type",          #kitchen_sep, flat,
         "in_room_grp",           #room category
         "water_source","latrine")          #warer, sanitation
#cluster--------------
#function
cluster_ratio <- function(cluster){
  cluster %>% 
    t() %>% t() %>% 
    as.data.frame()%>%
    summarise(ratio = round(Freq/sum(Freq)*100,digits = 2))
}

#cluster on material (wall, roof, floor) 
set.seed(41)
mat_clst <- nss76 %>%
  dplyr::select(floor,wall,roof)%>%
  kmodes(.,3,iter.max = 10, weight = FALSE)

mat_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_clst$modes)


#cluster on material (wall, roof, floor), kitchen
set.seed(40)
mat_k_clst <- nss76 %>%
  dplyr::select(floor,wall,roof,kit_type)%>%
  kmodes(.,3,iter.max = 10, weight = FALSE)

mat_k_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_clst$modes)

set.seed(40)
mat_k_clst <- nss76 %>%
  dplyr::select(floor,wall,roof,kit_type)%>%
  kmodes(.,4,iter.max = 10, weight = FALSE)

mat_k_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_clst$modes)


#cluster on material (wall, roof, floor), kitchen, room
set.seed(40)
mat_k_r_clst <- nss76 %>%
  dplyr::select(floor,wall,roof,kit_type,in_room_grp)%>%
  kmodes(.,4,iter.max = 10, weight = FALSE)

mat_k_r_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_r_clst$modes)

#cluster on water and sanitation
set.seed(40)
w_s_clst <- nss76 %>%
  dplyr::select(water_source,latrine)%>%
  na.omit()%>%
  kmodes(.,3,iter.max = 10, weight = FALSE)

w_s_clst$size %>% 
  cluster_ratio()%>%
  cbind(w_s_clst$modes)

#cluster all indicators
set.seed(40)
all_clst <- nss76 %>%
  dplyr::select(ind)%>%
  na.omit()%>%
  kmodes(.,4,iter.max = 10, weight = FALSE)

all_clst$size %>% 
  cluster_ratio()%>%
  cbind(all_clst$modes)

set.seed(41)
all_clst <- nss76 %>%
  dplyr::select(ind)%>%
  na.omit()%>%
  kmodes(.,5,iter.max = 10, weight = FALSE)

clst_final <-all_clst$size %>% 
  cluster_ratio()%>%
  cbind(all_clst$modes) 

clst_final %>%
  arrange(floor, wall,roof,-kit_type,dwell_type)%>%
  dplyr::select(-water_source,water_source) 

#statistics by cluster-----
nss76_clst <- nss76 %>%
  dplyr::filter_at(vars(ind),all_vars(!is.na(.)))%>%
  cbind(all_clst$cluster) %>%
  rename(cluster = `all_clst$cluster`) 

nss76_clst%>%
  group_by(cluster) %>%
  dplyr::summarise_at(vars(hq_nslum,legal_own,hh_size,hh_umce_ln,crowd_room),funs(weighted.mean(.,w=hh_weight, na.rm = TRUE)))
