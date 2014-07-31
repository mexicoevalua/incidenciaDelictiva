### Agregar abreviaturas para los nombres de los estados

### Cargar rgdal
require(rgdal)

# Cargar abreviaturas
codes  <-  read.csv("data/state_names.csv", encoding="utf8")
codes$state_code  <- sprintf("%02d", codes$state_code)
codes  <- codes[,-3]

# Load shapefile using "UTF-8". Notice the "." is the directory and the shapefile name 
# has no extention
shp  <- readOGR("shapefiles", "states", stringsAsFactors=FALSE, encoding="UTF-8")
# Explore with a quick plot
plot(shp, axes=TRUE, border="gray")

# Merge shapefile and csv
names(codes)
names(shp)
temp  <- merge(shp, codes, by.x="CVE_ENT", by.y="state_code") 
names(temp)

# Change name for short name
temp$NOM_ENT  <- temp$name

# Check your locale and set shapefile encoding to UTF-8
Sys.getlocale("LC_CTYPE")
getCPLConfigOption("SHAPE_ENCODING")
setCPLConfigOption("SHAPE_ENCODING", "UTF-8")

# Write merged shapefile using UTF-8
writeOGR(temp, "shapefiles", "states", driver="ESRI Shapefile", layer_options= c(encoding= "UTF-8"),
         overwrite_layer=T)