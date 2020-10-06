#This file is to generate cluster on NSS76 rural housing condition. 
#using k-modes
.libPaths("C:/Users/wb500886/Downloads/library")
library(tidyverse)
library(cluster)
library(klaR)
library(foreign)
library(readstata13)
library(skimr)
library(janitor)

#load data----
data_path <- "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/nss_data/NSS76/Data Output Files"
nss76_raw <- read.dta13(paste0(data_path,"/NSS76_All_clst_r.dta"))
nss76 <- nss76_raw %>%
  mutate(in_flat = recode(in_flat,
                           `100` = "Yes",
                           `0` = "No"),
         in_sep_kitch = recode(in_sep_kitch,
                          `100` = "Yes",
                          `0` = "No"),
         hq_period = recode(hq_period,
                            `1` = "<= 5",
                            `2` = "5 - 10",
                            `3` = "10 - 20",
                            `4` = "20 - 40",
                            `5` = "> 40"),
         in_all_permanent = recode(in_all_permanent,
                                   `0` = "No",
                                   `100` = "Yes"))

       
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
  dplyr::select(in_floor,in_wall,in_roof)%>%
  kmodes(.,3,iter.max = 10, weight = FALSE)

mat_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_clst$modes)


#cluster on material (wall, roof, floor), kitchen
set.seed(40)
mat_k_clst <- nss76 %>%
  dplyr::select(in_floor,in_wall,in_roof,in_sep_kitch)%>%
  kmodes(.,3,iter.max = 10, weight = FALSE)

mat_k_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_clst$modes)

set.seed(41)
mat_k_clst <- nss76 %>%
  dplyr::select(in_floor,in_wall,in_roof,in_sep_kitch)%>%
  kmodes(.,4,iter.max = 10, weight = FALSE)

mat_k_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_clst$modes)


#cluster on material (wall, roof, floor), kitchen, room
set.seed(42)
mat_k_r_clst <- nss76 %>%
  dplyr::select(in_floor,in_wall,in_roof,in_sep_kitch,in_room_grp)%>%
  kmodes(.,5,iter.max = 10, weight = FALSE)

mat_k_r_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_r_clst$modes)

set.seed(42)
mat_k_r_clst <- nss76 %>%
  dplyr::select(in_floor,in_wall,in_roof,in_sep_kitch,in_room_grp)%>%
  kmodes(.,6,iter.max = 10, weight = FALSE)

mat_k_r_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_r_clst$modes)

set.seed(42)
mat_k_r_clst <- nss76 %>%
  dplyr::select(in_floor,in_wall,in_roof,in_sep_kitch,in_room_grp)%>%
  kmodes(.,7,iter.max = 10, weight = FALSE)

mat_k_r_clst$size %>% 
  cluster_ratio()%>%
  cbind(mat_k_r_clst$modes)

#cluster on water and sanitation
set.seed(40)
w_s_clst <- nss76 %>%
  dplyr::select(h20,san)%>%
  na.omit()%>%
  kmodes(.,3,iter.max = 10, weight = FALSE)

w_s_clst$size %>% 
  cluster_ratio()%>%
  cbind(w_s_clst$modes)

set.seed(40)
w_s_clst <- nss76 %>%
  dplyr::select(h20,san)%>%
  na.omit()%>%
  kmodes(.,4,iter.max = 10, weight = FALSE)

w_s_clst$size %>% 
  cluster_ratio()%>%
  cbind(w_s_clst$modes)

#cluster all indicators
ind <- c(#"in_floor","in_wall","in_roof", #do not use single housing materials. 
         #"in_flat",  #do not use flat.
         "in_sep_kitch",        #kitchen_sep
         "in_room_grp",           #room category
         "h20","san"             #warer, sanitation
)  

set.seed(43) #all housing material as single variables hard to separate groups.
all_clst <- nss76 %>%
  dplyr::select("in_floor","in_wall","in_roof",ind)%>%
  na.omit()%>%
  kmodes(.,6,iter.max = 10, weight = FALSE)

all_clst$size %>% 
  cluster_ratio() %>%
  cbind(all_clst$modes) 

set.seed(45) #only using one variable for housing material:permanent structure
all_clst <- nss76 %>%
  dplyr::select(in_all_permanent,ind)%>%
  na.omit()%>%
  kmodes(.,6,iter.max = 10, weight = FALSE)

clst_result<-all_clst$size %>% 
  cluster_ratio() %>%
  cbind(all_clst$modes)
clst_result

# set.seed(46) #only using one variable for housing material: roof material. 
# all_clst_roof <- nss76 %>%
#   dplyr::select(in_roof,ind)%>%
#   na.omit()%>%
#   kmodes(.,6,iter.max = 10, weight = FALSE)
# 
# clst_result_roof<-all_clst_roof$size %>% 
#   cluster_ratio() %>%
#   cbind(all_clst_roof$modes)
# clst_result_roof

set.seed(45) #using housing period (good separation however limited data)
all_clst_own <- nss76 %>%
  dplyr::select(in_all_permanent,ind,hq_period)%>%
  na.omit()%>%
  kmodes(.,6,iter.max = 10, weight = FALSE)

clst_result_own<-all_clst_own$size %>% 
  cluster_ratio() %>%
  cbind(all_clst_own$modes)
clst_result_own   



#statistics by cluster-----
clst_table <- function(df){
  df %>%
    group_by(cluster) %>%
    dplyr::summarise(across(c(,legal_own),~weighted.mean(.,w=hh_weight, na.rm = TRUE)),
                     across(c(hh_umce,hh_size,in_ppl_room,cost_rent), ~median(.,na.rm = TRUE))) %>%
    dplyr::select(cluster,cost_rent,hh_umce,everything()) %>%
    mutate(#"Slum (%)" = round(100*(1-hq_nslum),digits = 2),
           "Ownership (%)" = round(100*legal_own,digits = 2),
           "P/R" = round(in_ppl_room,digits = 1)) %>%
    rename("Cons (Rs.)" = hh_umce,
           "Household Size" = hh_size,
           "Rent (Rs.)" = cost_rent) %>%
    dplyr::select( -legal_own, -in_ppl_room)
}

##with housing age.
nss76_clst_own <- nss76 %>%
  dplyr::filter_at(vars(in_all_permanent,ind,hq_period),all_vars(!is.na(.)))%>%
  mutate(cluster = all_clst_own$cluster)

result_own <- nss76_clst_own %>%
  mutate(across(c(in_all_permanent,ind,hq_period),as.factor)) %>%
  dplyr::select(in_all_permanent,ind,cluster,hq_period) %>%
  rename("Permanent Structure" = in_all_permanent,
         "Separate Kitchen" = in_sep_kitch,
         "Number of Rooms" = in_room_grp,
         "Water Access" = h20,
         "Sanitation Access" = san,
         "House Age" = hq_period) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))

result_own$the_summary

clst_stat_own <- nss76_clst_own %>%
  group_by(cluster) %>%
  dplyr::summarise(across(c(hq_nslum),~weighted.mean(.,w=hh_weight, na.rm = TRUE)),
                   across(c(hh_umce,hh_size,in_ppl_room), ~median(.,na.rm = TRUE))) %>%
  dplyr::select(cluster,hq_nslum,hh_umce,everything()) %>%
  mutate("Slum (%)" = round(100*(1-hq_nslum),digits = 2),
         #"Ownership (%)" = round(100*legal_own,digits = 2),
         "P/R" = round(in_ppl_room,digits = 1)) %>%
  rename("Cons (Rs.)" = hh_umce,
         "Household Size" = hh_size) %>%
  dplyr::select(-hq_nslum, -in_ppl_room)

clst_result_own%>%
  cbind(clst_stat_own) %>%
  arrange(`Cons (Rs.)`) %>%
  dplyr::select(cluster,everything())

##without housing age (permanent housing structure).
nss76_clst <- nss76 %>%
  dplyr::filter_at(vars(in_all_permanent,ind,-hq_period),all_vars(!is.na(.)))%>%
  mutate(cluster = all_clst$cluster)

result <- nss76_clst %>%
  mutate(across(c(in_all_permanent,ind),as.factor)) %>%
  dplyr::select(in_all_permanent,ind,cluster) %>%
  rename("Permanent Structure" = in_all_permanent,
         "Separate Kitchen" = in_sep_kitch,
         "Number of Rooms" = in_room_grp,
         "Water Access" = h20,
         "Sanitation Access" = san) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))
result$the_summary


clst_stat <- clst_table(nss76_clst)
  
clst_result%>%
  cbind(clst_stat) %>%
  arrange(`Cons (Rs.)`) %>%
  dplyr::select(cluster,everything())


##check the cluster: water
nss76_clst %>%
  filter(cluster == 2) %>%
  mutate(across(c(h20,b5_1),as.factor)) %>%
  dplyr::select(matches("h20"),b5_1) %>%
  summary()

nss76_clst %>%
  filter(cluster == 2) %>%
  mutate(across(c(h20,b5_1),as.factor)) %>%
  group_by(cluster) %>%
  tabyl(h20,b5_1) %>%
  adorn_totals(where = c("row","col")) %>%
  adorn_percentages(denominator = "row") %>%
  adorn_pct_formatting(digits = 0)


nss76_clst %>% 
  filter(!is.na(hh_umce)) %>%
  mutate(exp_10 = ntile(hh_umce,10))%>%
  group_by(exp_10) %>%
  summarise(h20_other = weighted.mean(h20_other,hh_weight))

##check the cluster: household size and mpce. 
nss76_clst %>%
  filter(cluster == 2 |
         cluster == 4) %>%
  group_by(cluster) %>%
  summarise(hh_size = weighted.mean(hh_size,hh_weight))

##cross-check with k-means----
nss76_kmeans<- read.dta13(paste0(data_path,"/NSS76_rural_kmeans.dta")) %>%
  dplyr::select(cluster,id,hh_umce) #renter is too limited, using umce for ranking. 
skim(nss76_kmeans)

rerank_mode <-nss76_clst %>%
  dplyr::select(id, cluster, hh_umce) %>%
  group_by(cluster) %>%
  summarise(med_umce = median(hh_umce, na.rm = TRUE)) %>%
  mutate(cluster_md = row_number(med_umce)) %>%
  right_join(nss76_clst, by = "cluster")%>%
  dplyr::select(id,cluster_md)

rerank_mean <- nss76_kmeans %>%
  dplyr::select(id, cluster, hh_umce) %>%
  group_by(cluster) %>%
  summarise(med_umce = median(hh_umce, na.rm = TRUE)) %>%
  mutate(cluster_mn = row_number(med_umce))%>%
  right_join(nss76_kmeans, by = "cluster") %>%
  dplyr::select(id,cluster_mn)
  
mean_mode <- rerank_mode %>%
  inner_join(rerank_mean, by= "id")

table(mean_mode$cluster_md,mean_mode$cluster_mn)

mean_mode %>%
  tabyl(cluster_md,cluster_mn) 

mean_mode %>%
  tabyl(cluster_md,cluster_mn) %>%
  adorn_totals(where = c("row","col")) %>%
  adorn_percentages(denominator = "row") %>%
  adorn_pct_formatting(digits = 0)
