############### SESYNC Research Support: plasticemission ########## 
## This script sets up the modeling pipeline for the plasticemission database
## 
## DATE CREATED: 08/16/2019
## DATE MODIFIED: 08/20/2019
## AUTHORS: Benoit Parmentier, Stephanie Borelle
## PROJECT: plasticemission working group
## ISSUE: accessing database and data imputation set up 
## TO DO:
##
## COMMIT: setting up connection to postgis db with password
##
## Useful links:
#https://rpubs.com/dgolicher/6373
#http://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
## TO DO: USE PG CONFIG!!! instead of ini file 

###################################################
#

###### Library used

library(gtools)                              # loading some useful tools 
library(sp)                                  # Spatial pacakge with class definition by Bivand et al.
library(sf)                                  # Spatial package with OGC standard definition, spatial object as df
library(rgdal)                               # GDAL wrapper for R, spatial utilities
library(gdata)                               # various tools with xls reading, cbindX
library(parallel)                            # Parallelization of processes with multiple cores
library(maptools)                            # Tools and functions for sp and other spatial objects e.g. spCbind
library(maps)                                # Tools and data for spatial/geographic objects
library(plyr)                                # Various tools including rbind.fill
library(ggplot2)
library(lubridate)
library(dplyr)
library(lattice)
library(gplots)
library(RPostgreSQL)
library(DBI)
library(RPostgres)

#
###### Functions used in this script and sourced from other files

create_dir_fun <- function(outDir,out_suffix=NULL){
  #if out_suffix is not null then append out_suffix string
  if(!is.null(out_suffix)){
    out_name <- paste("output_",out_suffix,sep="")
    outDir <- file.path(outDir,out_name)
  }
  #create if does not exists
  if(!file.exists(outDir)){
    dir.create(outDir)
  }
  return(outDir)
}

#Used to load RData object saved within the functions produced.
load_obj <- function(f){
  env <- new.env()
  nm <- load(f, env)[1]
  env[[nm]]
}

### Other functions for later ####

###This is where you can put the function 
#function_processing <- ".R" #PARAM 1
#script_path <- "/nfs/PlasticEmission-data/scripts"
#source(file.path(script_path,function_processing)) #source all functions used in this script 1.

############################################################################
####################  Parameters and argument set up ###########

in_dir <- "/nfs/bparmentier-data/"
out_dir <- "/nfs/PlasticEmission-data/tmp"

num_cores <- 2 #param 8 #normally I use only 1 core for this dataset but since I want to use the mclappy function the number of cores is changed to 2. If it was 1 then mclappy will be reverted back to the lapply function
create_out_dir_param=TRUE # param 9

out_suffix <-"postgis_data_08202019" #output suffix for the files and ouptut folder #param 12

### db related:
#db_ini_filename <- "/nfs/bparmentier-data/.pg_service.conf" #password info
db_ini_filename <- "/nfs/bparmentier-data/Data/projects/PlatsicEmission-data/postgis_init/plasticemission.ini" #password info

db_name <- "plasticemission"
db_user <- "plasticemission"
db_hostname <- "postgis02.research.sesync.org"

##############################  START SCRIPT  ############################

######### PART 0: Set up the output dir ################

if(is.null(out_dir)){
  out_dir <- in_dir #output will be created in the input dir
  
}
#out_dir <- in_dir #output will be created in the input dir

out_suffix_s <- out_suffix #can modify name of output suffix
if(create_out_dir_param==TRUE){
  out_dir <- create_dir_fun(out_dir,out_suffix)
  setwd(out_dir)
}else{
  setwd(out_dir) #use previoulsy defined directory
}

options(scipen=999)  #remove scientific writing

### PART I: READ IN SPATIAL DATA AND QUERY #######

##Here we are reading in the shapefile data into the database 
## From the command line:
## 1) ssh to sesync
## 2) connect to database: bparmentier@sshgw02:~$ psql -h postgis02.research.sesync.org -d plasticemission -U plasticemission

## 4) FROM R:
## Use /.pg_service.conf for better practice

##Read in password: 
db_password <- scan(db_ini_filename, character(), n = 1)
conn <- dbConnect(PostgreSQL(), 
                 dbname = db_name,
                 user = db_user,
                 password = db_password, 
                 host = db_hostname)

# List tables in the database 
dbListTables(conn)
#\dt in psql
dbListFields(conn, 'reference')

#SELECT * FROM region
sql_command <- "SELECT * FROM region"
region <- dbGetQuery(conn, sql_command) #this is a data.frame
sql_command <- "SELECT * FROM region where id LIKE 'S%'"
region_subset <- dbGetQuery(conn, sql_command) #this is a data.frame

#end with S
sql_command <- "SELECT * FROM region where id LIKE '%S'"
region_subset <- dbGetQuery(conn, sql_command) #this is a data.frame
region_subset

## Select the subset of data your interested in by location
sql_command <- "SELECT * FROM location"
location <- dbGetQuery(conn, sql_command)
class(location) # This is a data.frame

sql_command <- "SELECT COUNT(*) FROM value"
no_row <- dbGetQuery(conn, sql_command) #this is a data.frame
sql_command <- "SELECT COUNT(DISTINCT(location_id)) FROM value"
no_location <- dbGetQuery(conn, sql_command)
no_location #number of locations

sql_command <- "SELECT * FROM value"
value <- dbGetQuery(conn, sql_command) #this is a data.frame
value
dim(value)

sql_command <- "SELECT * FROM value JOIN location ON location_id = location.id WHERE name = 'Sri Lanka';"
value_join <- dbGetQuery(conn, sql_command) #this is a data.frame
value_join
dim(value_join)

### Writing out table in output directory defined earlier
write.table(value_join,file.path(out_dir,"value_join.txt"),sep=",")

### Now this how to extract data by country and variable:
sql_command <- "SELECT * FROM value JOIN location ON location_id = location.id"
value_df <- dbGetQuery(conn, sql_command) #this is a data.frame
dim(value_df)
list_countries <- unique(value_df$name)
length(list_countries)
dim(value_df)
#View(value_df)

##### Example for variable 
i <- 1
country_name <- list_countries[i]
varipasable_id <- 25

sql_command <- paste("SELECT * FROM value JOIN location ON location_id=location.id ", 
                     "WHERE name=",shQuote(country_name)," ",
                     "AND variable_id = ",variable_id, ";",sep="")

data_df <- dbGetQuery(conn, sql_command)  #Selecting station using a SQL query
## output dir

out_filename <- paste0("data_extracted_",country_name,".csv")
write.table(data_df,file.path(out_dir,out_filename),sep=",")


dbDisconnect(conn)

### Stage 2: imputation

### Stage 3: modeling 

### Stage 4: evaluation


#################### End of script ##################################


