library(eeguana)

download.file("http://www.ling.uni-potsdam.de/~nicenboim/files/faces.vhdr", 
              mode="wb", destfile="faces.vhdr")
download.file("http://www.ling.uni-potsdam.de/~nicenboim/files/faces.vmrk", 
              mode="wb", destfile="faces.vmrk")
download.file("http://www.ling.uni-potsdam.de/~nicenboim/files/faces.dat", 
              mode="wb", destfile="faces.dat")

faces <- read_vhdr("faces.vhdr")

data_faces_ERPs <- faces %>% 
  eeg_segment(description %in% c("s70", "s71"), 
          lim = c(-.2,.25)) %>%
  eeg_intervals_to_NA(type == "Bad Interval") %>% 
  ch_baseline() %>%  
  mutate(condition =
           if_else(description == "s70", "faces", "non-faces")) %>% 
  select(-type) %>% 
  group_by(.sample_id, condition) %>%
summarize_all_ch(mean,na.rm=TRUE)

pos_10 <- events(faces) %>% filter(type=="Stimulus", description =="s130") %>% pull(.sample_0) %>% .[10]

data_faces_10_trials <- faces  %>% filter(.sample_id <= pos_10)
  
usethis::use_data(data_faces_ERPs, data_faces_10_trials, overwrite=TRUE)