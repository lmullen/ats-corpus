library("internetarchive")
library("dplyr")
library("tidyr")
library("stringr")
library("loggr")
library("readr")

log_file("downloads.log")

ats_query <- c("publisher" = "american tract society", date = "1800 TO 1900")

if (!file.exists("items.rds")) {
  items <- ia_search(ats_query, num_results = 10e3) %>% ia_get_items()
  saveRDS(items, "items.rds")
} else {
  items <- readRDS("items.rds")
}

files <- items %>%
  ia_files() %>%
  filter(type == "txt",
         !str_detect(file, "xml_meta"), # don't need file format metadata
         !str_detect(file, "zip_meta"),
         !str_detect(file, "pdf_meta"),
         !str_detect(id, "americanmessenge")) # bad metadata from Internet Archive

suppressWarnings(dir.create("corpus"))
downloaded <- ia_download(files, dir = "corpus",
                          extended_name = FALSE, overwrite = FALSE)

# Prepare and tidy the metadata into a manifest
metadata <- ia_metadata(items)
metadata <- metadata %>%
  filter(field %in% c("title", "date", "subject", "publisher", "creator",
                      "contributor")) %>%
  spread(field, value)
manifest <- files %>%
  left_join(metadata, by = "id") %>%
  select(id, file, creator, title, publisher, date,
         subject, contributor) %>%
  mutate(file = str_c("corpus", file))


write_csv(manifest, "manifest.csv")
