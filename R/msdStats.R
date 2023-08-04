#' @title Main Mid Summer Drought Calculation Function
#'
#' @description This function calculates the different statistics of the mid summer drought from a RasterBrick or a Time Series.
#'
#' The input must be in the form of daily data, with the first data point being January 1st of a respective year.
#' If x is a SpatRaster, then the output is a SpatRaster with a data point for each year.
#'
#' @usage msdStats(x, dates, fcn)
#'
#' @param x         RasterBrick or TimeSeries
#' @param dates     Vector of Dates (from the msdDates function)
#' @param fcn       Specify what values to be pulled from the function. Options are 'duration', 'intensity', 'firstMax', 'secondMax', 'min', and 'mindex'.
#'
#' @return SpatRaster or TimeSeries of Yearly data
#'
#' @examples
#' # using spatRaster
#' # r<-terra::app(raster, msdStats, dates = d1, fcn="duration")
#'
#' @export
#'
#-----------------------------------------------------------------------------------------------------------------------------------------
msdStats <- function(x, dates, fcn){
  #check for valid arguments
  if(missing(dates)) {
    stop("missing dates argument in msdStats function")
  }
  if(!( fcn %in% c('duration', 'intensity', 'firstMax', 'secondMax', 'min', 'mindex'))){
    stop("fcn must be one of duration, intensity, firstMax, secondMax, min, mindex")
  }
  #-----------------------------------------------------------------------------------------------------------------------------------------
  data<-c(as.numeric(x)) #making sure the data is numeric #!! ERROR: nlyr(x) == 1 is not TRUE, but it's functional with a timeseries
  peaks<-quantmod::findPeaks(data)-1 #finding all of the peaks of the data
  valleys<-quantmod::findValleys(data)-1 #finding all of the valleys of the data
  output<-c(0) #creating a new variable
  #-----------------------------------------------------------------------------------------------------------------------------------------
  # Pull the values for the critical MSD dates (formerly ipdates2, msdDates)
  criticalDates = c(0)
  for(i in 1:length(dates)){
    if(dates[i] == 1){
      break
    }
    else{
      criticalDates = c(criticalDates, dates[i])
    }
  }
  criticalDates = criticalDates[ -c(1)]
  # Pull the values for the start and end of each year (formerly ipdates4, msdYear)
  yearDates = c(0)
  for(j in i:length(dates)){
    yearDates = c(yearDates, dates[j])
  }
  yearDates = yearDates[ -c(1)]
  #-----------------------------------------------------------------------------------------------------------------------------------------
  for (years in 1:(round(length(data)/365))){ #running for every year
    date1<-criticalDates[4*years-2] #the next six lines just pull the proper indices
    date2<-criticalDates[4*years-1]
    date3<-criticalDates[4*years-3]
    date4<-criticalDates[4*years]
    date5<-yearDates[2*years-1]
    date6<-yearDates[2*years]
    #checking for min valley between the inner dates
    min<-min(data[valleys[valleys>=date1 & valleys<=date2]],na.rm=TRUE)
    #checking for min valley between the outer dates
    min2<-min(data[valleys[valleys>=date3 & valleys<=date4]],na.rm=TRUE)

    mindate<-match(min, data) #finding the index of min
    mindate2<-match(min2, data) #finding the index of min2
    check1<-mindate==mindate2 #making sure that the index does overlap
    if (is.na(mindate)==TRUE){ #making sure we have a minimum, otherwise an NA is output
      output[years]<-NA
    }else{
      dates<-c(peaks[peaks>=date3 & peaks<=date4], mindate) #finding all the peaks between the outer dates
      dates<-sort(dates) #sorting them in order with the mindate
      mindex<-match(mindate,dates) #finding the index of the mindate
      maxdex1<-dates[1:(mindex-1)] #the next few lines find the max before the minimum and after
      maxdex2<-dates[(mindex+1):length(dates)]
      maxpos1<-data[maxdex1]
      maxpos2<-data[maxdex2]
      max1<-max(maxpos1,na.rm=TRUE)
      max2<-max(maxpos2,na.rm=TRUE)
      pos1<-match(max1,maxpos1)
      pos2<-match(max2,maxpos2)
      index1<-maxdex1[pos1]
      index2<-maxdex2[pos2]
      maxcheck1<-max(data[date5:mindate],na.rm=TRUE) #making sure that the max is the real between january and mindex
      maxcheck2<-max(data[mindate:date6],na.rm=TRUE) #making sure that the max is the real between mindex and december
      maxval1<-max1==maxcheck1
      maxval2<-max2==maxcheck2
      max1<-max1*maxval1
      max2<-max2*maxval2
      if (is.na(check1)==TRUE){ #making sure that the minimum is the minimum
        output[years]<-NA
      }else if (length(max1)==0){#the next couple ensure that we have values to pull from
        output[years]<-NA
      }else if (length(max2)==0){
        output[years]<-NA
      }else if (is.na(max1)==TRUE){
        output[years]<-NA
      }else if (is.na(max2)==TRUE){
        output[years]<-NA
      }else if (max1==0){
        output[years]<-NA
      }else if (max2==0){
        output[years]<-NA
      }
      else if (fcn=="duration"){ #the different cases to choose from for 'fcn'
        output[years]<-index2-index1
      }else if (fcn=="intensity"){
        output[years]<-((max1+max2)/2)-min
      }else if (fcn=="firstMax"){
        output[years]<-max1
      }else if (fcn=="secondMax"){
        output[years]<-max2
      }else if (fcn=="min"){
        output[years]<-min
      }else if (fcn=="mindex"){
        output[years]<-index1
      }else
        output[years]<-NA
    }
  }
  return(output)
}