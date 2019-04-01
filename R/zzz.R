stop("not load dplyr and ggplot at the beg")

.onLoad <- function(...) {
    register_s3_method("dplyr", "group_by", "eeg_lst")
    register_s3_method("dplyr", "filter", "eeg_lst")
    register_s3_method("dplyr", "summarise", "eeg_lst")
    register_s3_method("dplyr", "mutate", "eeg_lst")
    register_s3_method("dplyr", "arrange", "eeg_lst")
    register_s3_method("dplyr", "select", "eeg_lst")
    register_s3_method("dplyr", "select", "ica_lst")
    register_s3_method("dplyr", "rename", "eeg_lst")
    register_s3_method("dplyr", "rename", "ica_lst")
    register_s3_method("dplyr", "left_join", "eeg_lst")
    invisible()
}

register_s3_method <- function(pkg, generic, class, fun = NULL) {
    stopifnot(is.character(pkg), length(pkg) == 1)
    stopifnot(is.character(generic), length(generic) == 1)
    stopifnot(is.character(class), length(class) == 1)

    if (is.null(fun)) {
        fun <- get(paste0(generic, ".", class), envir = parent.frame())
    } else {
        stopifnot(is.function(fun))
    }

    if (pkg %in% loadedNamespaces()) {
        registerS3method(generic, class, fun, envir = asNamespace(pkg))
    }

                                        # Always register hook in case package is later unloaded & reloaded
    setHook(
        packageEvent(pkg, "onLoad"),
        function(...) {
            registerS3method(generic, class, fun, envir = asNamespace(pkg))
        }
    )
}
                                        # nocov end

if(getRversion() >= "2.15.1")
    utils::globalVariables(
		c(".", unlist(obligatory_cols),
		  "..cols","..cols_events","..cols_events_temp","..cols_signal",
		  "..cols_signal_temp",".GRP",".I",".N",".SD",".lower",".new_id",".sid",".upper",".x",".y",
		  "BinaryFormat","DataFile","DataFormat","DataOrientation","L","MarkerFile",
		  "Mk_number=Type","SamplingInterval","V1","V2","amplitude",
		  "channel","","i..sample_0",
		  "i..size","lowerb","mk","n","offset","","recording","resolution",
		  "scale_fill_gradientn","time","type","value","x..lower","x..sample_id"
		  )
	)
