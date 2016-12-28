# https://data.cityofboston.gov/Public-Safety/Crime-Incident-Reports-July-2012-August-2015-Sourc/7cdf-6fgx

# Dependencies
dependent <- c("ggmap", "data.table", "reshape2", "ggplot2", "dplyr", "forecast", "quantmod",
               "tseries", "stats", "dynlm", "vars", "scales")
lapply(dependent, library, character.only = TRUE)

# ggmap citation
# D. Kahle and H. Wickham. ggmap: Spatial Visualization with ggplot2. The R Journal, 5(1),
# 144-161. URL http://journal.r-project.org/archive/2013-1/kahle-wickham.pdf

# terror trends
# immigrant trends
# demographic shifts

# Set your working directory
setwd("~/crime")

# read in the data
crimeRaw <- read.csv(file = "BostonCrime.csv", header = TRUE, sep = ",")

# split off the Lat/Long coordinates
crimeBoston <- data.frame(crimeRaw, colsplit(crimeRaw$Location, pattern = "\\,", names = c("Lat", "Long")))
crimeBoston$Lat <- as.numeric(sub(pattern = "\\(", replacement = "", x = crimeBoston$Lat))
crimeBoston$Long <- as.numeric(sub(pattern = "\\)", replacement = "", x = crimeBoston$Long))
str(crimeBoston)

# Fix the date formats
crimeBoston$FROMDATE <- as.character(crimeBoston$FROMDATE)
crimeBoston$DATE <- as.Date(crimeBoston$FROMDATE, format = "%m/%d/%Y %I:%M:%S %p")
crimeBoston$MONTH <- as.Date(cut(crimeBoston$DATE, breaks = "month"))
crimeBoston$WEEK <- as.Date(cut(crimeBoston$DATE, breaks = "week", start.on.monday = FALSE))
crimeBoston$DAY <- as.Date(cut(crimeBoston$DATE, breaks = "day"))
crimeBoston$HOUR <- as.Date(cut(crimeBoston$DATE, breaks = "hour"))


# Explore crime types
unique(crimeBoston$INCIDENT_TYPE_DESCRIPTION)
barplot(prop.table(table(crimeBoston$INCIDENT_TYPE_DESCRIPTION)))
table(crimeBoston$INCIDENT_TYPE_DESCRIPTION)

# Fix repeat variables
crimeBoston$INCIDENT_TYPE_DESCRIPTION <- toupper(crimeBoston$INCIDENT_TYPE_DESCRIPTION)

# Create crime buckets
violentCrime <- c("AGGRAVATED ASSAULT", "SIMPLE ASSAULT", "DEATH INVESTIGATION", "HOMICIDE", "MANSLAUG")
sexCrimes <- c("CRIMES AGAINST CHILDREN", "SEXREG", "PROSTITUTION CHARGES", "SEX OFFENDER REGISTRATION",
               "PROSTITUTION", "RAPE AND ATTEMPTED")
propertyCrimes <- c("RESIDENTIAL BURGLARY", "ROBBERY", "COMMERCIAL BURGLARY", "PROPLOST", "OTHER LARCENY",
                    "AUTO THEFT", "VANDALISM", "LARCENY FROM MOTOR VEHICLE", "FIRE", "ARSON",
                    "PROPERTY RELATED DAMAGE", "OTHER BURGLARY")

# Subset the dataset on the buckets
violence <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% violentCrime)
violenceMonth <- as.data.frame(table(violence$MONTH))
colnames(violenceMonth) <- c("Date", "Total")
violenceMonth$Date <- as.character(violenceMonth$Date)
violenceMonth$Date <- as.Date(violenceMonth$Date, format = "%Y-%m-%d")
# Drop the last observation...something is wrong with it
violenceMonth[38,] <- NA

sex <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% sexCrimes)
sexMonth <- as.data.frame(table(sex$MONTH))
colnames(sexMonth) <- c("Date", "Total")
sexMonth$Date <- as.character(sexMonth$Date)
sexMonth$Date <- as.Date(sexMonth$Date, format = "%Y-%m-%d")
sexMonth[38,] <- NA


property <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% propertyCrimes)
propertyMonth <- as.data.frame(table(property$MONTH))
colnames(propertyMonth) <- c("Date", "Total")
propertyMonth$Date <- as.character(propertyMonth$Date)
propertyMonth$Date <- as.Date(propertyMonth$Date, format = "%Y-%m-%d")
propertyMonth[38,] <- NA
propertyMonth[37,] <- NA

# Exploratory plots
# Monthly violent crime
crimeMonth <- ggplot(violenceMonth, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Violent Crime in Boston (JUL 2012 - JUL 2015)", 
       x = "Month", y = "Violent Crime by Month") +
  stat_smooth(method = "lm", se = TRUE, fill = "black", colour = "black", aes(group = 1)) + 
  scale_x_date(date_labels = "%Y %b")
# Need to fix x-axis scale. Change trendline color. Add "," on y-axis. 
crimeMonth

# Sex crimes
SexCrimeMonth <- ggplot(sexMonth, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Sex Crimes in Boston (JUL 2012 - JUL 2015)", 
       x = "Month", y = "Sex Crimes by Month") +
  stat_smooth(method = "lm", se = TRUE, fill = "black", colour = "black", aes(group = 1)) + 
  scale_x_date(date_labels = "%Y %b")
# Need to fix x-axis scale. Change trendline color. Add "," on y-axis. 
SexCrimeMonth

# Property Crimes
propertyCrimeMonth <- ggplot(propertyMonth, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Property Crimes in Boston (JUL 2012 - JUN 2015)", 
       x = "Month", y = "Property Crimes by Month") +
  stat_smooth(method = "lm", se = TRUE, fill = "black", colour = "black", aes(group = 1)) + 
  scale_x_date(date_labels = "%Y %b")
# Need to fix x-axis scale. Change trendline color. Add "," on y-axis. 
propertyCrimeMonth


# Start making some heat maps
# Create base map for Boston
BostonBase <- get_map(location = c(-71.057083, 42.361145), zoom = 12, maptype = "roadmap", 
                  source = "google")
BostonMap <- ggmap(BostonBase, fullpage = TRUE)

# violent crime maps
map1 <- ggmap(BostonBase, extent = "panel") + 
        geom_density2d(data = violence, aes(x = Long, y = Lat), size = 0.3) +
        stat_density2d(data = violence, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
              size = 0.01, n = 50, geom = "polygon") +
        scale_fill_gradient(low = "green", high = "red") +
        scale_alpha(range = c(0, 0.25), guide = FALSE) +
        labs(title = "Violent Crime in Boston 2012-2015", x = "Longitude", y = "Latitude") 
map1

# Sex crime maps
map2 <- ggmap(BostonBase, extent = "panel") +
        geom_density2d(data = sex, aes(x = Long, y = Lat), size = 0.3) +
        stat_density_2d(data = sex, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
              size = 0.01, n = 50, geom = "polygon") +
        scale_fill_gradient(low = "green", high = "red") +
        scale_alpha(range = c(0, 0.25), guide = FALSE) +
        labs(title = "Sex Crimes in Boston 2012-2015", x = "Longitude", y = "Latitude")
map2

# Property crime maps
map3 <- ggmap(BostonBase, extent = "panel") +
        geom_density2d(data = sex, aes(x = Long, y = Lat), size = 0.3) +
        stat_density_2d(data = sex, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
              size = 0.01, n = 50, geom = "polygon") +
        scale_fill_gradient(low = "green", high = "red") +
        scale_alpha(range = c(0, 0.25), guide = FALSE) +
        labs(title = "Property Crimes in Boston 2012-2015", x = "Longitude",  y = "Latitude")
map3

# Hourly plots of the crime variables
crimeHours <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% violentCrime)
crimeHours <- as.data.frame(table(crimeBoston))



crimeHour <- ggplot(violenceHour, aes(x = Date, y = Total)) +
             geom_line(position = "identity", aes(group = 1)) +
             labs(title = "Violent Crime in Boston (JUL 2012 - JUL 2015)", 
             x = "Hour", y = "Violent Crime by Hour") +
             stat_smooth(method = "lm", se = TRUE, fill = "black", colour = "black", aes(group = 1)) + 
             scale_x_date(date_labels = "%I")
# Need to fix x-axis scale. Change trendline color. Add "," on y-axis. 
crimeHour          








