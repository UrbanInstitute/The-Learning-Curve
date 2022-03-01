# Pulling number of parolees per county
pdf = "https://www.cdcr.ca.gov/research/wp-content/uploads/sites/174/2021/06/201906_DataPoints.pdf"
new_pdf_name = "/parolee.pdf"

download.file(pdf,
              paste0(downloads_folder,new_pdf_name),
              mode = "wb")
extracted_tables <- pdftools::pdf_text(
  paste0(downloads_folder,new_pdf_name))

table_data = extracted_tables[181]
rm(extracted_tables)
data = as.character(sub(".*June 2019 Releases Number of","",table_data))
data = iconv(data, from = "latin1", to = "UTF-8")
D2 = strsplit(data, split = "â\u0097¦")
D2 = trimws(gsub("\n","",unlist(D2)),"both")
D2 = gsub("(Counties in Range)|(Releases by County)", "", D2)
D2 = as.data.frame(D2[grep("[A-z]+:",D2)])
colnames(D2) = "Raw"
D2$county = paste(gsub(":.*","",D2$Raw),"County, California")
D2$parolees = gsub(".*: ","",D2$Raw)
D2$parolees = as.numeric(gsub("[[:punct:]]","",D2$parolees))
D2 = D2%>%
  select(!c("Raw"))
D3 = merge(CENSUS_API,D2,
      by.x = "NAME",
      by.y = "county")