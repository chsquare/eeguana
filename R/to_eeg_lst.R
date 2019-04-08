
#' @export
as_eeg_lst.mne.io.base.BaseRaw <- function(.data){

    ##create channel info
    ch_names <- .data$ch_names
    ## Meaning of kind code: https://github.com/mne-tools/mne-python/blob/2a0a55c6a795f618cf0a1603e22a72ee8e879f62/mne/io/constants.py
    ## FIFF.FIFFV_BIO_CH       = 102
    ## FIFF.FIFFV_MEG_CH       =   1
    ## FIFF.FIFFV_REF_MEG_CH   = 301
    ## FIFF.FIFFV_EEG_CH       =   2
    ## FIFF.FIFFV_MCG_CH       = 201
    ## FIFF.FIFFV_STIM_CH      =   3
    ## FIFF.FIFFV_EOG_CH       = 202
    ## FIFF.FIFFV_EMG_CH       = 302
    ## FIFF.FIFFV_ECG_CH       = 402
    ## FIFF.FIFFV_MISC_CH      = 502
    ## FIFF.FIFFV_RESP_CH      = 602  # Respiration monitoring
    ## FIFF.FIFFV_SEEG_CH      = 802  # stereotactic EEG
    ## FIFF.FIFFV_SYST_CH      = 900  # some system status information (on Triux systems only)
    ## FIFF.FIFFV_ECOG_CH      = 902
    ## FIFF.FIFFV_IAS_CH       = 910  # Internal Active Shielding data (maybe on Triux only)
    ## FIFF.FIFFV_EXCI_CH      = 920  # flux excitation channel used to be a stimulus channel
    ## FIFF.FIFFV_DIPOLE_WAVE  = 1000  # Dipole time curve (xplotter/xfit)
    ## FIFF.FIFFV_GOODNESS_FIT = 1001  # Goodness of fit (xplotter/xfit)
    ## FIFF.FIFFV_FNIRS_CH = 1100 # Functional near-infrared spectroscopy
                                        # SI derived units
                                        #
    ## FIFF.FIFF_UNIT_MOL_M3 = 10  # mol/m^3
    ## FIFF.FIFF_UNIT_HZ  = 101  # hertz
    ## FIFF.FIFF_UNIT_N   = 102  # Newton
    ## FIFF.FIFF_UNIT_PA  = 103  # pascal
    ## FIFF.FIFF_UNIT_J   = 104  # joule
    ## FIFF.FIFF_UNIT_W   = 105  # watt
    ## FIFF.FIFF_UNIT_C   = 106  # coulomb
    ## FIFF.FIFF_UNIT_V   = 107  # volt
    ## FIFF.FIFF_UNIT_F   = 108  # farad
    ## FIFF.FIFF_UNIT_OHM = 109  # ohm
    ## FIFF.FIFF_UNIT_MHO = 110  # one per ohm
    ## FIFF.FIFF_UNIT_WB  = 111  # weber
    ## FIFF.FIFF_UNIT_T   = 112  # tesla
    ## FIFF.FIFF_UNIT_H   = 113  # Henry
    ## FIFF.FIFF_UNIT_CEL = 114  # celsius
    ## FIFF.FIFF_UNIT_LM  = 115  # lumen
    ## FIFF.FIFF_UNIT_LX  = 116  # lux
    ##                                     #
    ##                                     # Others we need
    ##                                     #
    ## FIFF.FIFF_UNIT_T_M   = 201  # T/m
    ## FIFF.FIFF_UNIT_AM    = 202  # Am
    ## FIFF.FIFF_UNIT_AM_M2 = 203  # Am/m^2
    ## FIFF.FIFF_UNIT_AM_M3 = 204 # Am/m^3

    rel_ch <- .data$info$chs %>% purrr::discard(~ .x$kind  == 3)
    sti_ch_names <- .data$info$chs %>% purrr::keep(~ .x$kind  == 3) %>%
        purrr::map_chr(~ .x$ch_name)
    if(length(sti_ch_names) >0 ){
        warning("Stimuli channels will be discarded")
    }

    scale_head <- purrr::map_dbl(rel_ch, ~ sqrt(sum((0 - .x$loc)^2)) ) %>%
        .[.!=0] %>% # remove the ones that have all 0
        min(na.rm = TRUE) 
        
    ch_info <- rel_ch %>% purrr::map_dfr(function(ch) {
        if(ch$kind %in% c(502)) { #misc channel
            location <- rep(NA_real_,3)
        } else {
            location <- purrr::map(ch$loc[1:3], ~ round(./scale_head,2))
        } 
        units_list <- c("mol/m^3","hertz","newton","pascal","joule","watt","coulomb",
                        "volt","farad","ohm",
                        "S","weber","tesla","henry","celsius","lumen","lux") %>%
            setNames(c(10,101:116) %>% as.character()) %>%
            as.list()
        prefix <- c("","deci","centi","milli","micro","nano") %>%
            setNames(c(0,-1:-3,-6,-9) %>% as.character)

        if(!ch$unit %in% as.numeric(names(units_list))) ch$unit <- 107  #default to Volts

        list(channel= ch$ch_name,
             ".x" = location[[1]],
             ".y" = location[[2]],
             ".z" = location[[3]],
             unit = paste0(prefix[[log10(ch$range)%>% as.character()]],
                                   units_list[[ch$unit %>% as.character()]]) ,
             .reference = NA
                                                        )})

    signal_m <- .data$to_data_frame()
    data.table::setDT(signal_m)
    if(length(sti_ch_names)>0){
        signal_m[, (sti_ch_names):=NULL]
    }

    t_s <- .data$times
    samples <- as_sample_int(c(t_s), sampling_rate= .data$info$sfreq)
    
    new_signal <- signal_tbl(signal_m, 1L,samples,ch_info)

                                        #create events object
    ann <- .data$annotations$`__dict__`
    if(length(ann$onset)==0){
        new_events <-events_tbl()
    } else{
    new_events <- events_tbl(.id = 1L,
                             .sample_0 = ann$onset %>%
                                 as_sample_int(sampling_rate = .data$info$sfreq) %>% as.integer,
                             .size = ann$duration %>%
                                 {as_sample_int(. ,sampling_rate = .data$info$sfreq)-1L} %>%
                                 as.integer,
                             .channel = NA_character_,
                             descriptions_dt = data.table::data.table(description = ann$description))
    }
    eeg_lst(signal = new_signal,
            events= new_events,
            segments = tibble::tibble(.id=1L,recording="recording1", segment=1L))

}