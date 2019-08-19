############### SESYNC Research Support: plasticemission ########## 
## This script sets up the modeling pipeline for the plasticemission database
## 
## DATE CREATED: 08/16/2019
## DATE MODIFIED: 08/19/2019
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
library(spdep)                               # Spatial pacakge with methods and spatial stat. by Bivand et al.
library(rgdal)                               # GDAL wrapper for R, spatial utilities
library(gdata)                               # various tools with xls reading, cbindX
library(raster)                              # Raster and image processing in R
library(rasterVis)                           # Raster plotting functions
library(parallel)                            # Parallelization of processes with multiple cores
library(maptools)                            # Tools and functions for sp and other spatial objects e.g. spCbind
library(maps)                                # Tools and data for spatial/geographic objects
library(plyr)                                # Various tools including rbind.fill
library(spgwr)                               # GWR method
library(rgeos)                               # Geometric, topologic library of functions
library(gridExtra)                           # Combining lattice plots
library(colorRamps)                          # Palette/color ramps for symbology
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

#function_processing <- ".R" #PARAM 1

#script_path <- "/nfs/bparmentier-data/Data/projects/supplychaincommitments/scripts"
#script_path <- "/nfs/supplychaincommitments-data/scripts"

#source(file.path(script_path,function_processing)) #source all functions used in this script 1.

############################################################################
####################  Parameters and argument set up ###########

in_dir <- "/nfs/bparmentier-data/"
out_dir <- "/nfs/PlasticEmission-data/tmp"

num_cores <- 2 #param 8 #normally I use only 1 core for this dataset but since I want to use the mclappy function the number of cores is changed to 2. If it was 1 then mclappy will be reverted back to the lapply function
create_out_dir_param=TRUE # param 9

out_suffix <-"postgis_data_08162019" #output suffix for the files and ouptut folder #param 12

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

#Load data into PostgreSQL from ESRI shape file 
##Read in password: 
db_password <- scan(db_ini_filename, character(), n = 1)


## Use /.pg_service.conf for better practice
#conn <- dbConnect(Postgres(), 
#                  service = 'plasticemission')
 
#Load data into PostgreSQL from ESRI shape file 
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
location

sql_command <- "SELECT COUNT(*) FROM value"
no_row <- dbGetQuery(conn, sql_command) #this is a data.frame
sql_command <- "SELECT COUNT(DISTINCT(location_id)) FROM value"
no_location <- dbGetQuery(conn, sql_command)
no_location

sql_command <- "SELECT * FROM value"
value <- dbGetQuery(conn, sql_command) #this is a data.frame
value
dim(value)

sql_command <- "SELECT * FROM value JOIN location ON location_id = location.id WHERE name = 'Sri Lanka';"
value_join <- dbGetQuery(conn, sql_command) #this is a data.frame
value_join
dim(value_join)

write.table(value_join,file.path(out_dir,"value_join.txt"),sep=",")

sql_command <- "COPY temperature TO '/nfs/PlasticEmission-data/tmp/value_join2.csv' DELIMITER ',' CSV HEADER;"
test <- dbGetQuery(conn, sql_command) #this is a data.frame

#> test <- dbGetQuery(conn, sql_command) #this is a data.frame
#Error in postgresqlExecStatement(conn, statement, ...) : 
#  RS-DBI driver: (could not Retrieve the result : ERROR:  must be superuser to COPY to or from a file
#                  HINT:  Anyone can COPY to stdout or from stdin. psql's \copy command also works for anyone.
#)
#Warning message:
#In postgresqlQuickSQL(conn, statement, ...) :
#  Could not create execute: COPY temperature TO '//nfs/PlasticEmission-data/tmp/value_join2.csv' DELIMITER ',' CSV HEADER;

#COPY temperature TO '/home/bparmentier/Data/Benoit/Databases/postgres/outputs/temperature.csv' DELIMITER ',' CSV HEADER;

sql_command <- "SELECT * FROM value JOIN location ON location_id = location.id WHERE name = 'Estonia' and variable_id = 25"
value_estonia <- dbGetQuery(conn, sql_command) #this is a data.frame
class(value_estonia)

## imputation

### modeling 

## output dir
write.table(value_estonia,file.path(out_dir,"value_estonia.txt"),sep=",")

#SELECT name FROM (SELECT name FROM agentinformation) as a  

sql_command <- "SELECT id, year,value FROM (SELECT * FROM value JOIN location ON location_id = location.id WHERE name = 'Estonia' and variable_id = 25) AS estonia"
sql_command <- "SELECT id, year,value FROM (SELECT * FROM value JOIN location ON location_id = location.id WHERE name = 'Estonia' and variable_id = 25) AS estonia"

value_estonia2 <- dbGetQuery(conn, sql_command) #this is a data.frame
class(value_estonia2)

write.table(value_estonia,file.path(out_dir,"value_estonia.txt"),sep=",")

dbDisconnect(conn)

#################### End of script ##################################


